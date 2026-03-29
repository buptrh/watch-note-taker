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
    @Published var lastSavedText: String?
    @Published var errorMessage: String?

    private let transcriptionEngine: any Transcribing
    private let vaultWriter: VaultWriter
    private let noteStore: any NoteStoring
    private let connector = WatchPhoneConnector.shared
    private let sessionManager = SessionManager()
    private var recordingDate: Date?
    private var isFinalizing = false

    var onRecordingSaved: ((String, Date, TimeInterval) -> Void)?

    init(transcriptionEngine: any Transcribing, vaultWriter: VaultWriter, noteStore: any NoteStoring) {
        self.transcriptionEngine = transcriptionEngine
        self.vaultWriter = vaultWriter
        self.noteStore = noteStore

        connector.onAudioChunkReceived = { [weak self] data, date in
            Task { @MainActor in
                await self?.processChunk(data: data, date: date)
            }
        }

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
        if !isWatchRecording && !isFinalizing {
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
        isFinalizing = true
        isWatchRecording = false

        // Wait briefly for any in-flight transcriptions to complete.
        // isFinalizing prevents late-arriving chunks from resetting liveTranscript.
        try? await Task.sleep(for: .seconds(1))

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
                lastSavedText = fullText
                errorMessage = nil
                onRecordingSaved?(fullText, date, 0)
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }

        isFinalizing = false
        sessionManager.stopKeepAlive()
    }
}
