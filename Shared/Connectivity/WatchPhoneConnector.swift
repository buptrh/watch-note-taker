import Foundation
import WatchConnectivity
import AVFoundation

/// Handles WatchConnectivity between watch and phone.
/// Hybrid delivery: sendMessage when reachable (with retry), transferFile as fallback.
/// Broadcasts recording state bidirectionally for UI sync.
final class WatchPhoneConnector: NSObject, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = WatchPhoneConnector()

    @Published var isReachable = false
    @Published var pendingTransfers: Int = 0

    /// Remote device recording state
    @Published var remoteIsRecording = false
    @Published var remoteDevice: String? = nil // "watch" or "phone"

    /// Called on the phone when an audio chunk arrives (real-time or queued file)
    var onAudioChunkReceived: ((Data, Date) -> Void)?

    /// Called on the watch when transcription text comes back from the phone
    var onTranscriptionReceived: ((String) -> Void)?

    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    private var heartbeatTimer: Timer?
    private var remoteTimeoutTimer: Timer?

    #if os(watchOS)
    private let localDevice = "watch"
    #else
    private let localDevice = "phone"
    #endif

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Recording State Sync

    /// Broadcast local recording state to the other device
    func sendRecordingStateChanged(isRecording: Bool) {
        let device = localDevice

        if isRecording {
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                    self?.sendStateSyncMessage(isRecording: true, device: device)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = nil
            }
        }

        sendStateSyncMessage(isRecording: isRecording, device: device)
    }

    private func sendStateSyncMessage(isRecording: Bool, device: String) {
        let message: [String: Any] = [
            "type": "recordingStateSync",
            "isRecording": isRecording,
            "device": device
        ]
        sendMessageBestEffort(message)
    }

    /// Request remote state (called on app launch / reachability change)
    func sendStatePing() {
        let message: [String: Any] = [
            "type": "recordingStatePing",
            "device": localDevice,
            "isRecording": false // local state — the remote will reply with theirs
        ]
        sendMessageBestEffort(message)
    }

    private func handleRecordingStateSync(_ message: [String: Any]) {
        guard let isRecording = message["isRecording"] as? Bool,
              let device = message["device"] as? String else { return }

        DispatchQueue.main.async {
            self.remoteIsRecording = isRecording
            self.remoteDevice = isRecording ? device : nil

            if isRecording {
                self.resetRemoteTimeout()
            } else {
                self.remoteTimeoutTimer?.invalidate()
                self.remoteTimeoutTimer = nil
            }
        }
    }

    private func resetRemoteTimeout() {
        remoteTimeoutTimer?.invalidate()
        remoteTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.remoteIsRecording = false
                self?.remoteDevice = nil
            }
        }
    }

    private func clearRemoteStateAfterDelay(_ delay: TimeInterval) {
        remoteTimeoutTimer?.invalidate()
        remoteTimeoutTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.remoteIsRecording = false
                self?.remoteDevice = nil
            }
        }
    }

    /// Best-effort send — no retry, no fallback. Used for state sync.
    private func sendMessageBestEffort(_ message: [String: Any]) {
        let session = WCSession.default
        guard session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Watch → Phone: Send audio chunk (hybrid with retry)

    func sendAudioChunk(_ audioData: Data, recordingDate: Date) {
        let session = WCSession.default

        if session.isReachable {
            sendMessageWithRetry(audioData: audioData, date: recordingDate, attempt: 1)
        } else {
            queueAudioFile(audioData, recordingDate: recordingDate)
        }
    }

    private func sendMessageWithRetry(audioData: Data, date: Date, attempt: Int) {
        let message: [String: Any] = [
            "type": "audioChunk",
            "audio": audioData,
            "date": date.timeIntervalSince1970
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] error in
            guard let self else { return }

            if attempt < self.maxRetries {
                DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                    if WCSession.default.isReachable {
                        self.sendMessageWithRetry(audioData: audioData, date: date, attempt: attempt + 1)
                    } else {
                        self.queueAudioFile(audioData, recordingDate: date)
                    }
                }
            } else {
                self.queueAudioFile(audioData, recordingDate: date)
            }
        }
    }

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
            DispatchQueue.main.async {
                self.pendingTransfers += 1
            }
        } catch {
            print("Failed to queue audio file: \(error)")
        }
    }

    func sendRecordingComplete(date: Date) {
        let session = WCSession.default

        if session.isReachable {
            let message: [String: Any] = [
                "type": "recordingComplete",
                "date": date.timeIntervalSince1970
            ]
            session.sendMessage(message, replyHandler: nil) { [weak self] _ in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    if WCSession.default.isReachable {
                        WCSession.default.sendMessage(message, replyHandler: nil)
                    }
                }
            }
        }
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
        if reachable {
            sendStatePing()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        DispatchQueue.main.async {
            self.isReachable = reachable
            if reachable {
                self.sendStatePing()
            } else if self.remoteIsRecording {
                // Grace period before clearing remote state
                self.clearRemoteStateAfterDelay(5)
            }
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
            DispatchQueue.main.async {
                self.pendingTransfers = max(0, self.pendingTransfers - 1)
            }
        } catch {
            print("Failed to read transferred file: \(error)")
        }
    }

    // File transfer completed (watch side confirmation)
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error {
            if let metadata = fileTransfer.file.metadata,
               let timestamp = metadata["date"] as? TimeInterval {
                let date = Date(timeIntervalSince1970: timestamp)
                do {
                    let data = try Data(contentsOf: fileTransfer.file.fileURL)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.queueAudioFile(data, recordingDate: date)
                    }
                } catch {
                    print("Retry failed — could not read file: \(error)")
                }
            }
            print("File transfer failed: \(error.localizedDescription)")
        } else {
            DispatchQueue.main.async {
                self.pendingTransfers = max(0, self.pendingTransfers - 1)
            }
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

        case "recordingComplete":
            NotificationCenter.default.post(name: Notification.Name("watchRecordingComplete"), object: nil)

        case "transcription":
            guard let text = message["text"] as? String else { return }
            onTranscriptionReceived?(text)

        case "recordingStateSync":
            handleRecordingStateSync(message)

        case "recordingStatePing":
            // Reply with our current state — not recording (idle) or recording
            // For now, we don't track our own state here, so reply with false
            // The ViewModel will call sendRecordingStateChanged on start/stop
            break

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
