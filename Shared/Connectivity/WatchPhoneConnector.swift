import Foundation
import WatchConnectivity
import AVFoundation

/// Handles WatchConnectivity between watch and phone.
/// Hybrid delivery: sendMessage when reachable, transferFile when not.
final class WatchPhoneConnector: NSObject, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = WatchPhoneConnector()

    @Published var isReachable = false

    /// Called on the phone when an audio chunk arrives (real-time or queued file)
    var onAudioChunkReceived: ((Data, Date) -> Void)?

    /// Called on the watch when transcription text comes back from the phone
    var onTranscriptionReceived: ((String) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Watch → Phone: Send audio chunk (hybrid)

    /// Send audio chunk — uses sendMessage if reachable, transferFile if not
    func sendAudioChunk(_ audioData: Data, recordingDate: Date) {
        let session = WCSession.default

        if session.isReachable {
            // Real-time delivery
            let message: [String: Any] = [
                "type": "audioChunk",
                "audio": audioData,
                "date": recordingDate.timeIntervalSince1970
            ]
            session.sendMessage(message, replyHandler: nil) { [weak self] error in
                // sendMessage failed — fall back to transferFile
                print("sendMessage failed, queueing file: \(error.localizedDescription)")
                self?.queueAudioFile(audioData, recordingDate: recordingDate)
            }
        } else {
            // Phone not reachable — queue for later
            queueAudioFile(audioData, recordingDate: recordingDate)
        }
    }

    /// Queue audio as a file transfer (delivered when phone app opens)
    private func queueAudioFile(_ audioData: Data, recordingDate: Date) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chunk_\(Int(recordingDate.timeIntervalSince1970))_\(UUID().uuidString.prefix(8)).wav")

        do {
            try audioData.write(to: tempURL)
            let metadata: [String: Any] = [
                "type": "audioChunk",
                "date": recordingDate.timeIntervalSince1970
            ]
            WCSession.default.transferFile(tempURL, metadata: metadata)
        } catch {
            print("Failed to queue audio file: \(error)")
        }
    }

    /// Send final chunk marker
    func sendRecordingComplete(date: Date) {
        let session = WCSession.default

        if session.isReachable {
            let message: [String: Any] = [
                "type": "recordingComplete",
                "date": date.timeIntervalSince1970
            ]
            session.sendMessage(message, replyHandler: nil)
        }
        // If not reachable, phone will process queued files when it opens
    }

    // MARK: - Phone → Watch: Send transcription back

    func sendTranscriptionToWatch(_ text: String) {
        let session = WCSession.default

        if session.isReachable {
            let message: [String: Any] = [
                "type": "transcription",
                "text": text
            ]
            session.sendMessage(message, replyHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let reachable = session.isReachable
        DispatchQueue.main.async {
            self.isReachable = reachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        DispatchQueue.main.async {
            self.isReachable = reachable
        }
    }

    // Real-time message received
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }

    // File transfer received (queued delivery)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata,
              let type = metadata["type"] as? String,
              type == "audioChunk",
              let timestamp = metadata["date"] as? TimeInterval else { return }

        let date = Date(timeIntervalSince1970: timestamp)

        do {
            let audioData = try Data(contentsOf: file.fileURL)
            onAudioChunkReceived?(audioData, date)
        } catch {
            print("Failed to read transferred file: \(error)")
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "audioChunk":
            guard let audioData = message["audio"] as? Data,
                  let timestamp = message["date"] as? TimeInterval else { return }
            let date = Date(timeIntervalSince1970: timestamp)
            onAudioChunkReceived?(audioData, date)

        case "transcription":
            guard let text = message["text"] as? String else { return }
            onTranscriptionReceived?(text)

        default:
            break
        }
    }

    // MARK: - iOS only

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
