import AVFoundation
import Observation

@Observable
@MainActor
final class RecordingViewModel: RecordingToggleable {

    private(set) var state: RecordingState = .idle
    private(set) var errorMessage: String?
    private(set) var lastCaptureTimestamp: Date?
    private(set) var lastTranscribedText: String?
    private(set) var chunksTranscribed: Int = 0

    private let audioRecorder: AudioRecorder
    private let transcriptionEngine: any Transcribing
    private let noteStore: any NoteStoring
    private let sessionManager = SessionManager()
    private let connector = WatchPhoneConnector.shared

    /// If true, stream audio chunks to iPhone for transcription instead of transcribing locally
    var usePhoneRelay: Bool = false

    init(
        audioRecorder: AudioRecorder,
        transcriptionEngine: any Transcribing,
        noteStore: any NoteStoring
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionEngine = transcriptionEngine
        self.noteStore = noteStore

        // Listen for transcriptions from phone
        connector.onTranscriptionReceived = { [weak self] text in
            Task { @MainActor in
                self?.handlePhoneTranscription(text)
            }
        }
    }

    func prewarmModel() async {
        await transcriptionEngine.prewarm()
    }

    func toggleRecording() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .transcribing, .saving:
            break
        }
    }

    private func startRecording() {
        errorMessage = nil
        chunksTranscribed = 0
        lastTranscribedText = nil
        state = .recording

        let shouldStream = usePhoneRelay && connector.isReachable

        if shouldStream {
            // Set up chunk streaming to iPhone
            audioRecorder.onChunkReady = { [weak self] buffers in
                guard let data = AudioConverter.buffersToWAVData(buffers) else { return }
                self?.connector.sendAudioChunk(data, recordingDate: Date())
            }
        }

        Task {
            do {
                sessionManager.startKeepAlive()
                try await audioRecorder.start(streaming: shouldStream)
            } catch {
                sessionManager.stopKeepAlive()
                state = .idle
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    private func stopRecording() {
        let wasStreaming = usePhoneRelay && connector.isReachable
        state = .transcribing

        Task {
            do {
                let buffer = try await audioRecorder.stop()
                audioRecorder.onChunkReady = nil

                if wasStreaming {
                    // Tell phone we're done; remaining chunk already sent via flush
                    connector.sendRecordingComplete(date: Date())
                    // Phone handles transcription + saving; we just wait briefly
                    try await Task.sleep(for: .seconds(1))
                    sessionManager.stopKeepAlive()
                    state = .idle
                    if lastTranscribedText == nil {
                        lastTranscribedText = "Sent to iPhone for transcription"
                    }
                    lastCaptureTimestamp = Date()
                } else {
                    // Local transcription (fallback or phone app)
                    let text = try await transcriptionEngine.transcribe(buffer: buffer)

                    state = .saving
                    let now = Date()
                    let entry = MarkdownFormatter.formatEntry(text: text, at: now)
                    try noteStore.save(entry: entry, for: now)

                    lastCaptureTimestamp = now
                    lastTranscribedText = text
                    sessionManager.stopKeepAlive()
                    state = .idle
                }
            } catch {
                sessionManager.stopKeepAlive()
                state = .idle
                errorMessage = "[\(type(of: error))] \(error)"
            }
        }
    }

    private func handlePhoneTranscription(_ text: String) {
        chunksTranscribed += 1
        lastTranscribedText = text
    }
}
