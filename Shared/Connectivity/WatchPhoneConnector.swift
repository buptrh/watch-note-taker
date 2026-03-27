import Foundation
import WatchConnectivity
import AVFoundation

/// Handles WatchConnectivity between watch and phone.
/// Watch side: sends audio chunks. Phone side: receives and processes them.
final class WatchPhoneConnector: NSObject, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = WatchPhoneConnector()

    @Published var isReachable = false

    /// Called on the phone when an audio chunk arrives from the watch
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

    // MARK: - Watch → Phone: Send audio chunk

    func sendAudioChunk(_ audioData: Data, recordingDate: Date) {
        guard WCSession.default.isReachable else { return }

        let message: [String: Any] = [
            "type": "audioChunk",
            "audio": audioData,
            "date": recordingDate.timeIntervalSince1970
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Send audio chunk failed: \(error.localizedDescription)")
        }
    }

    /// Send final chunk marker so phone knows recording is done
    func sendRecordingComplete(date: Date) {
        guard WCSession.default.isReachable else { return }

        let message: [String: Any] = [
            "type": "recordingComplete",
            "date": date.timeIntervalSince1970
        ]

        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Phone → Watch: Send transcription back

    func sendTranscriptionToWatch(_ text: String) {
        guard WCSession.default.isReachable else { return }

        let message: [String: Any] = [
            "type": "transcription",
            "text": text
        ]

        WCSession.default.sendMessage(message, replyHandler: nil)
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

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "audioChunk":
            guard let audioData = message["audio"] as? Data,
                  let timestamp = message["date"] as? TimeInterval else { return }
            let date = Date(timeIntervalSince1970: timestamp)
            onAudioChunkReceived?(audioData, date)

        case "recordingComplete":
            // Phone can finalize processing if needed
            break

        case "transcription":
            guard let text = message["text"] as? String else { return }
            onTranscriptionReceived?(text)

        default:
            break
        }
    }

    // MARK: - iOS only delegate methods

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
