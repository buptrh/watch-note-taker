import Foundation
import WatchConnectivity

/// Watch ↔ Phone communication layer.
///
/// Three channels, each for the right purpose:
/// - applicationContext: State sync (connection, recording status). Guaranteed, latest-wins.
/// - transferFile: Audio chunks. Queued, reliable, any size.
/// - sendMessage: Real-time transcription text. Best-effort, only when reachable.
final class WatchPhoneConnector: NSObject, WCSessionDelegate, ObservableObject, @unchecked Sendable {

    static let shared = WatchPhoneConnector()

    // MARK: - Published State

    @Published var isConnected = false
    @Published var remoteIsRecording = false
    @Published var remoteDevice: String? = nil
    @Published var pendingTransfers: Int = 0

    // MARK: - Callbacks

    var onAudioChunkReceived: ((Data, Date) -> Void)?
    var onTranscriptionReceived: ((String) -> Void)?

    // MARK: - Private

    private var localIsRecording = false
    private var lastHeardFrom: Date?
    private var connectionTimer: Timer?
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

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - State Sync via applicationContext (guaranteed delivery)

    /// Broadcast current state. Uses applicationContext — always delivered, latest wins.
    func sendRecordingStateChanged(isRecording: Bool) {
        localIsRecording = isRecording
        broadcastContext()

        if isRecording {
            // Heartbeat: update context every 3s so the other side knows we're still recording
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                    self?.broadcastContext()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = nil
            }
        }
    }

    /// Send our state via applicationContext
    private func broadcastContext() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        let context: [String: Any] = [
            "device": localDevice,
            "isRecording": localIsRecording,
            "timestamp": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("[WPC] Failed to update context: \(error)")
        }
    }

    // MARK: - Audio (always file transfer)

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

    // MARK: - Recording Complete (file transfer for reliability)

    func sendRecordingComplete(date: Date) {
        // Use file transfer — guaranteed delivery even if app isn't active
        let emptyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("complete_\(UUID().uuidString.prefix(8)).signal")
        try? Data().write(to: emptyURL)
        let metadata: [String: Any] = [
            "type": "recordingComplete",
            "date": date.timeIntervalSince1970
        ]
        WCSession.default.transferFile(emptyURL, metadata: metadata)

        // Also try sendMessage for faster delivery if reachable
        if WCSession.default.isReachable {
            let message: [String: Any] = ["type": "recordingComplete", "date": date.timeIntervalSince1970]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }

    // MARK: - Transcription (best-effort real-time)

    func sendTranscriptionToWatch(_ text: String) {
        guard WCSession.default.isReachable else { return }
        let message: [String: Any] = ["type": "transcription", "text": text]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Connection Monitoring

    private func startConnectionMonitor() {
        DispatchQueue.main.async {
            self.connectionTimer?.invalidate()
            self.connectionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                guard let self else { return }
                if let last = self.lastHeardFrom, Date().timeIntervalSince(last) > 30 {
                    self.isConnected = false
                    self.remoteIsRecording = false
                    self.remoteDevice = nil
                }
            }
        }
    }

    private func markConnected() {
        lastHeardFrom = Date()
        DispatchQueue.main.async {
            if !self.isConnected { self.isConnected = true }
        }
    }

    // MARK: - WCSessionDelegate: Activation

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            startConnectionMonitor()
            broadcastContext()

            // Check if there's already a context from the other side
            let received = session.receivedApplicationContext
            if !received.isEmpty {
                handleContext(received)
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            broadcastContext()
        }
    }

    // MARK: - WCSessionDelegate: Application Context

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleContext(applicationContext)
    }

    private func handleContext(_ context: [String: Any]) {
        guard let device = context["device"] as? String,
              let isRecording = context["isRecording"] as? Bool else { return }

        markConnected()

        DispatchQueue.main.async {
            self.remoteIsRecording = isRecording
            self.remoteDevice = isRecording ? device : nil
        }
    }

    // MARK: - WCSessionDelegate: Messages

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        markConnected()
        handleMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        markConnected()
        handleMessage(message)
        replyHandler(["device": localDevice, "isRecording": localIsRecording])
    }

    // MARK: - WCSessionDelegate: File Transfer

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        markConnected()
        guard let metadata = file.metadata, let type = metadata["type"] as? String else { return }

        switch type {
        case "audioChunk":
            if let timestamp = metadata["date"] as? TimeInterval,
               let data = try? Data(contentsOf: file.fileURL) {
                onAudioChunkReceived?(data, Date(timeIntervalSince1970: timestamp))
            }
        case "recordingComplete":
            NotificationCenter.default.post(name: .watchRecordingComplete, object: nil)
        default:
            break
        }

        DispatchQueue.main.async { self.pendingTransfers = max(0, self.pendingTransfers - 1) }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        DispatchQueue.main.async { self.pendingTransfers = max(0, self.pendingTransfers - 1) }
    }

    // MARK: - Message Dispatch

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "audioChunk":
            if let data = message["audio"] as? Data, let ts = message["date"] as? TimeInterval {
                onAudioChunkReceived?(data, Date(timeIntervalSince1970: ts))
            }
        case "recordingComplete":
            NotificationCenter.default.post(name: .watchRecordingComplete, object: nil)
        case "transcription":
            if let text = message["text"] as? String {
                onTranscriptionReceived?(text)
            }
        default:
            break
        }
    }

    // MARK: - iOS Only

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}

extension Notification.Name {
    static let watchRecordingComplete = Notification.Name("watchRecordingComplete")
}
