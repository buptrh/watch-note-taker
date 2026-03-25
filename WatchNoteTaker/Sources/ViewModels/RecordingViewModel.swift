import AVFoundation
import Observation

@Observable
@MainActor
final class RecordingViewModel: RecordingToggleable {

    private(set) var state: RecordingState = .idle
    private(set) var errorMessage: String?
    private(set) var lastCaptureTimestamp: Date?
    private(set) var lastTranscribedText: String?

    private let audioRecorder: any AudioRecording
    private let transcriptionEngine: any Transcribing
    private let noteStore: any NoteStoring

    init(
        audioRecorder: any AudioRecording,
        transcriptionEngine: any Transcribing,
        noteStore: any NoteStoring
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionEngine = transcriptionEngine
        self.noteStore = noteStore
    }

    func toggleRecording() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .transcribing, .saving:
            // Ignore toggle during processing
            break
        }
    }

    private func startRecording() {
        errorMessage = nil
        state = .recording

        Task {
            do {
                try await audioRecorder.start()
            } catch {
                state = .idle
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    private func stopRecording() {
        state = .transcribing

        Task {
            do {
                let buffer = try await audioRecorder.stop()

                let text = try await transcriptionEngine.transcribe(buffer: buffer)

                state = .saving
                let now = Date()
                let entry = MarkdownFormatter.formatEntry(text: text, at: now)
                try noteStore.save(entry: entry, for: now)

                lastCaptureTimestamp = now
                lastTranscribedText = text
                state = .idle
            } catch {
                state = .idle
                errorMessage = "Capture failed: \(error.localizedDescription)"
            }
        }
    }
}
