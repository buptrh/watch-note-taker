import Foundation

/// Runs on iPhone. Receives audio chunks from watch, transcribes them,
/// writes to Obsidian vault, and sends confirmation back to watch.
@MainActor
final class PhoneTranscriptionService: ObservableObject {

    @Published var isProcessing = false
    @Published var chunksProcessed = 0
    @Published var lastText: String?

    private let transcriptionEngine: any Transcribing
    private let vaultWriter: VaultWriter
    private let noteStore: any NoteStoring
    private let connector = WatchPhoneConnector.shared
    private let sessionManager = SessionManager()

    init(transcriptionEngine: any Transcribing, vaultWriter: VaultWriter, noteStore: any NoteStoring) {
        self.transcriptionEngine = transcriptionEngine
        self.vaultWriter = vaultWriter
        self.noteStore = noteStore

        connector.onAudioChunkReceived = { [weak self] data, date in
            Task { @MainActor in
                await self?.processChunk(data: data, date: date)
            }
        }
    }

    func prewarm() async {
        await transcriptionEngine.prewarm()
    }

    private func processChunk(data: Data, date: Date) async {
        isProcessing = true
        sessionManager.startKeepAlive()

        guard let tempURL = AudioConverter.wavDataToTempFile(data) else {
            isProcessing = false
            return
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            // Load audio and transcribe
            let audioFile = try AVAudioFile(forReading: tempURL)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else { return }
            try audioFile.read(into: buffer)

            let text = try await transcriptionEngine.transcribe(buffer: buffer)
            let entry = MarkdownFormatter.formatEntry(text: text, at: date)

            // Write to vault if access is set up, otherwise local
            if vaultWriter.hasVaultAccess {
                try vaultWriter.saveToVault(entry: entry, for: date)
            } else {
                try noteStore.save(entry: entry, for: date)
            }

            chunksProcessed += 1
            lastText = text

            // Send transcription back to watch
            connector.sendTranscriptionToWatch(text)
        } catch {
            print("Chunk transcription failed: \(error)")
        }

        isProcessing = false
        sessionManager.stopKeepAlive()
    }
}

import AVFoundation
