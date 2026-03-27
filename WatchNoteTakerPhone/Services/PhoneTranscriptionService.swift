import Foundation
import AVFoundation

/// Runs on iPhone. Receives audio chunks from watch, transcribes them,
/// accumulates text, saves ONE entry when recording completes, and sends text back to watch.
@MainActor
final class PhoneTranscriptionService: ObservableObject {

    @Published var isWatchRecording = false
    @Published var isTranscribing = false
    @Published var liveTranscript: String = ""
    @Published var chunksProcessed: Int = 0

    private let transcriptionEngine: any Transcribing
    private let vaultWriter: VaultWriter
    private let noteStore: any NoteStoring
    private let connector = WatchPhoneConnector.shared
    private let sessionManager = SessionManager()
    private var recordingDate: Date?

    init(transcriptionEngine: any Transcribing, vaultWriter: VaultWriter, noteStore: any NoteStoring) {
        self.transcriptionEngine = transcriptionEngine
        self.vaultWriter = vaultWriter
        self.noteStore = noteStore

        connector.onAudioChunkReceived = { [weak self] data, date in
            Task { @MainActor in
                await self?.processChunk(data: data, date: date)
            }
        }

        // Listen for recording complete from watch
        let existingHandler = connector.onTranscriptionReceived
        // We need a separate handler for recordingComplete
        // Override the message handler to also catch recordingComplete
        NotificationCenter.default.addObserver(
            forName: .watchRecordingComplete,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.finalizeRecording()
            }
        }
    }

    func prewarm() async {
        await transcriptionEngine.prewarm()
    }

    private func processChunk(data: Data, date: Date) async {
        if !isWatchRecording {
            isWatchRecording = true
            recordingDate = date
            liveTranscript = ""
            chunksProcessed = 0
        }

        isTranscribing = true
        sessionManager.startKeepAlive()

        guard let tempURL = AudioConverter.wavDataToTempFile(data) else {
            isTranscribing = false
            return
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            let audioFile = try AVAudioFile(forReading: tempURL)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else { return }
            try audioFile.read(into: buffer)

            let text = try await transcriptionEngine.transcribe(buffer: buffer)

            chunksProcessed += 1
            if liveTranscript.isEmpty {
                liveTranscript = text
            } else {
                liveTranscript += " " + text
            }

            // Send transcription back to watch for live display
            connector.sendTranscriptionToWatch(text)
        } catch {
            print("Chunk transcription failed: \(error)")
        }

        isTranscribing = false
    }

    func finalizeRecording() async {
        guard isWatchRecording else { return }
        isWatchRecording = false

        // Wait briefly for any in-flight transcriptions
        try? await Task.sleep(for: .seconds(1))

        // Save accumulated transcript as ONE entry
        let date = recordingDate ?? Date()
        let fullText = liveTranscript

        if !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let entry = MarkdownFormatter.formatEntry(text: fullText, at: date)
            do {
                if vaultWriter.hasVaultAccess {
                    try vaultWriter.saveToVault(entry: entry, for: date)
                } else {
                    try noteStore.save(entry: entry, for: date)
                }
            } catch {
                print("Failed to save watch recording: \(error)")
            }
        }

        sessionManager.stopKeepAlive()
    }
}

extension Notification.Name {
    static let watchRecordingComplete = Notification.Name("watchRecordingComplete")
}
