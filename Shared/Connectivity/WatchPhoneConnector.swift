import Foundation
import WatchConnectivity

/// Watch ↔ Phone communication layer.
///
/// Design principles:
/// - Audio always uses transferFile (sendMessage has ~65KB limit)
/// - Small messages (state sync, transcription) use sendMessage with replyHandler
/// - isConnected is based on "heard from the other app recently", not WCSession.isReachable
/// - All handlers must be registered BEFORE activate() is called
final class WatchPhoneConnector: NSObject, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = WatchPhoneConnector()

    // MARK: - Published State

    /// True when we've heard from the other app within the last 30 seconds
    @Published var isConnected = false

    /// The other device is currently recording
    @Published var remoteIsRecording = false

    /// Which device is recording remotely ("watch" or "phone")
    @Published var remoteDevice: String? = nil

    /// Number of pending file transfers
    @Published var pendingTransfers: Int = 0

    // MARK: - Callbacks (set by consumers BEFORE activate)

    /// Phone receives audio chunks from watch
    var onAudioChunkReceived: ((Data, Date) -> Void)?

    /// Watch receives transcription text from phone
    var onTranscriptionReceived: ((String) -> Void)?

    // MARK: - Private State

    private var localIsRecording = false
    private var lastHeardFrom: Date?
    private var connectionCheckTimer: Timer?
    private var heartbeatTimer: Timer?

    #if os(watchOS)
    private let localDevice = "watch"
    #else
    private let localDevice = "phone"
    #endif

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle

    /// Activate WCSession. Call AFTER all handlers are registered.
    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        startConnectionCheck()
    }

    /// Periodic check: if we haven't heard from the other app in 30s, mark disconnected
    private func startConnectionCheck() {
        DispatchQueue.main.async {
            self.connectionCheckTimer?.invalidate()
            self.connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                guard let self else { return }
                if let last = self.lastHeardFrom, Date().timeIntervalSince(last) > 30 {
                    self.isConnected = false
                    if self.remoteIsRecording {
                        self.remoteIsRecording = false
                        self.remoteDevice = nil
                    }
                }
            }
        }
    }

    /// Mark that we received something from the other app
    private func markConnected() {
        lastHeardFrom = Date()
        DispatchQueue.main.async {
            if !self.isConnected { self.isConnected = true }
        }
    }

    // MARK: - Send: Audio Chunks (ALWAYS file transfer)

    func sendAudioChunk(_ audioData: Data, recordingDate: Date) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("chunk_\(UUID().uuidString.prefix(8)).wav")

        do {
            try audioData.write(to: tempURL)
            let metadata: [String: Any] = [
                "type": "audioChunk",
                "date": recordingDate.timeIntervalSince1970
            ]
            WCSession.default.transferFile(tempURL, metadata: metadata)
            DispatchQueue.main.async { self.pendingTransfers += 1 }
        } catch {
            print("[WPC] Failed to write audio chunk: \(error)")
        }
    }

    // MARK: - Send: Recording Complete

    func sendRecordingComplete(date: Date) {
        let message: [String: Any] = [
            "type": "recordingComplete",
            "date": date.timeIntervalSince1970
        ]

        // Try real-time first
        sendWithReply(message) { success in
            if !success {
                // Fallback: send as file transfer metadata (always delivered eventually)
                let emptyURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("complete_\(UUID().uuidString.prefix(8)).signal")
                try? Data().write(to: emptyURL)
                let metadata: [String: Any] = [
                    "type": "recordingComplete",
                    "date": date.timeIntervalSince1970
                ]
                WCSession.default.transferFile(emptyURL, metadata: metadata)
            }
        }
    }

    // MARK: - Send: Transcription (phone → watch)

    func sendTranscriptionToWatch(_ text: String) {
        let message: [String: Any] = [
            "type": "transcription",
            "text": text
        ]
        sendWithReply(message)
    }

    // MARK: - Send: Recording State Sync

    func sendRecordingStateChanged(isRecording: Bool) {
        localIsRecording = isRecording

        if isRecording {
            // Send immediately + heartbeat every 3s
            sendStateSync(isRecording: true)
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                    self?.sendStateSync(isRecording: true)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = nil
            }
            // Send stop twice for reliability
            sendStateSync(isRecording: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendStateSync(isRecording: false)
            }
        }
    }

    private func sendStateSync(isRecording: Bool) {
        let message: [String: Any] = [
            "type": "recordingStateSync",
            "isRecording": isRecording,
            "device": localDevice
        ]
        sendWithReply(message)
    }

    /// Send a ping to discover the other app. Called on activation and reachability change.
    func sendStatePing() {
        let message: [String: Any] = [
            "type": "ping",
            "device": localDevice,
            "isRecording": localIsRecording
        ]
        sendWithReply(message)
    }

    // MARK: - Core Send Helper

    /// Send a message with replyHandler. On success, mark connected. On failure, do nothing
    /// (don't mark disconnected — the connection check timer handles that).
    private func sendWithReply(_ message: [String: Any], completion: ((Bool) -> Void)? = nil) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            completion?(false)
            return
        }

        // Always try sendMessage regardless of isReachable
        // (iOS isReachable is unreliable for watch)
        session.sendMessage(message, replyHandler: { reply in
            let isRec = reply["isRecording"] as? Bool ?? false
            let dev = reply["device"] as? String
            DispatchQueue.main.async { [weak self] in
                self?.markConnected()
                self?.remoteIsRecording = isRec
                self?.remoteDevice = isRec ? dev : nil
            }
            completion?(true)
        }, errorHandler: { _ in
            completion?(false)
        })
    }

    // MARK: - WCSessionDelegate: Activation

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            // Try to discover the other app
            sendStatePing()
            // Retry a few times in case the other app isn't ready yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.sendStatePing() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.sendStatePing() }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            sendStatePing()
        }
    }

    // MARK: - WCSessionDelegate: Receive Messages

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        markConnected()
        handleMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        markConnected()
        handleMessage(message)

        // Always reply with our current state
        let reply: [String: Any] = [
            "device": localDevice,
            "isRecording": localIsRecording
        ]
        replyHandler(reply)
    }

    // MARK: - WCSessionDelegate: Receive Files

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        markConnected()

        guard let metadata = file.metadata,
              let type = metadata["type"] as? String else { return }

        switch type {
        case "audioChunk":
            guard let timestamp = metadata["date"] as? TimeInterval else { return }
            let date = Date(timeIntervalSince1970: timestamp)
            if let data = try? Data(contentsOf: file.fileURL) {
                onAudioChunkReceived?(data, date)
            }

        case "recordingComplete":
            NotificationCenter.default.post(name: .watchRecordingComplete, object: nil)

        default:
            break
        }

        DispatchQueue.main.async {
            self.pendingTransfers = max(0, self.pendingTransfers - 1)
        }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        DispatchQueue.main.async {
            self.pendingTransfers = max(0, self.pendingTransfers - 1)
        }
        if let error {
            print("[WPC] File transfer failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Message Dispatch

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "audioChunk":
            // Audio via sendMessage (legacy, shouldn't happen with new code)
            if let audioData = message["audio"] as? Data,
               let timestamp = message["date"] as? TimeInterval {
                onAudioChunkReceived?(audioData, Date(timeIntervalSince1970: timestamp))
            }

        case "recordingComplete":
            NotificationCenter.default.post(name: .watchRecordingComplete, object: nil)

        case "transcription":
            if let text = message["text"] as? String {
                onTranscriptionReceived?(text)
            }

        case "recordingStateSync":
            if let isRecording = message["isRecording"] as? Bool,
               let device = message["device"] as? String {
                DispatchQueue.main.async {
                    self.remoteIsRecording = isRecording
                    self.remoteDevice = isRecording ? device : nil
                }
            }

        case "ping":
            // Ping received — we already replied via replyHandler
            // Also process their state
            if let isRecording = message["isRecording"] as? Bool,
               let device = message["device"] as? String {
                DispatchQueue.main.async {
                    self.remoteIsRecording = isRecording
                    self.remoteDevice = isRecording ? device : nil
                }
            }

        default:
            break
        }
    }

    // MARK: - iOS Only

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

// MARK: - Notifications

extension Notification.Name {
    static let watchRecordingComplete = Notification.Name("watchRecordingComplete")
}
