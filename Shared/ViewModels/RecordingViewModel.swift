import AVFoundation
import Observation

enum TranscriptionMode: String {
    case phoneStream = "Streaming to iPhone"
    case localTranscription = "Local transcription"
    case phoneChunking = "Progressive transcription"
}

@Observable
@MainActor
final class RecordingViewModel: RecordingToggleable {

    private(set) var state: RecordingState = .idle
    private(set) var errorMessage: String?
    private(set) var lastCaptureTimestamp: Date?
    private(set) var lastTranscribedText: String?
    private(set) var chunksTranscribed: Int = 0
    private(set) var activeMode: TranscriptionMode?

    /// Running transcript — appended as chunks are transcribed
    private(set) var liveTranscript: String = ""

    /// Recording duration in seconds — updates every second while recording
    private(set) var recordingDuration: TimeInterval = 0

    private let audioRecorder: AudioRecorder
    private let transcriptionEngine: any Transcribing
    private let noteStore: any NoteStoring
    private let sessionManager = SessionManager()
    private let connector = WatchPhoneConnector.shared
    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    /// If true, prefer streaming to iPhone when reachable
    var preferPhoneRelay: Bool = false

    /// If true, transcribe chunks progressively during local recording (phone app)
    var useLocalChunking: Bool = false

    init(
        audioRecorder: AudioRecorder,
        transcriptionEngine: any Transcribing,
        noteStore: any NoteStoring
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionEngine = transcriptionEngine
        self.noteStore = noteStore

        connector.onTranscriptionReceived = { [weak self] text in
            Task { @MainActor in
                self?.handleTranscriptionResult(text)
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
        liveTranscript = ""
        recordingStartTime = Date()
        recordingDuration = 0
        state = .recording

        // Start duration timer
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }

        let phoneReachable = preferPhoneRelay && connector.isReachable
        let useStreaming = phoneReachable || useLocalChunking

        if phoneReachable {
            activeMode = .phoneStream
            audioRecorder.onChunkReady = { [weak self] buffers in
                guard let data = AudioConverter.buffersToWAVData(buffers) else { return }
                self?.connector.sendAudioChunk(data, recordingDate: Date())
                // Also transcribe locally to build live transcript
                self?.transcribeChunkForPreview(buffers)
            }
        } else if useLocalChunking {
            activeMode = .phoneChunking
            audioRecorder.onChunkReady = { [weak self] buffers in
                self?.transcribeChunkForPreview(buffers)
            }
        } else {
            activeMode = .localTranscription
        }

        Task {
            do {
                sessionManager.startKeepAlive()
                try await audioRecorder.start(streaming: useStreaming)
            } catch {
                sessionManager.stopKeepAlive()
                activeMode = nil
                state = .idle
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    private func stopRecording() {
        durationTimer?.invalidate()
        durationTimer = nil
        let wasStreaming = activeMode == .phoneStream || activeMode == .phoneChunking

        state = .transcribing

        Task {
            do {
                let chunksSoFar = chunksTranscribed

                // Replace callback to capture flush without triggering transcription
                var flushBuffers: [AVAudioPCMBuffer]?
                audioRecorder.onChunkReady = { buffers in
                    flushBuffers = buffers
                }

                // stop() triggers VAD flush → captured in flushBuffers (not transcribed)
                let fullBuffer = try await audioRecorder.stop()
                audioRecorder.onChunkReady = nil

                if wasStreaming && chunksSoFar > 0 {
                    // Chunks were transcribed during recording.
                    // Transcribe the remaining flush segment if any.
                    if let remaining = flushBuffers,
                       let merged = AudioRecorder.mergeBuffers(remaining) {
                        do {
                            let text = try await transcriptionEngine.transcribe(buffer: merged)
                            handleTranscriptionResult(text)
                        } catch {
                            // Last chunk failed — not critical, we have the earlier chunks
                        }
                    }
                } else {
                    // No chunks were transcribed (short recording or non-streaming).
                    // Transcribe the full recording at once.
                    let text = try await transcriptionEngine.transcribe(buffer: fullBuffer)
                    liveTranscript = text
                }

                // Save the complete transcript as ONE entry
                state = .saving
                let now = recordingStartTime ?? Date()
                let fullText = liveTranscript

                if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Nothing transcribed — not an error, just nothing to save
                    sessionManager.stopKeepAlive()
                    activeMode = nil
                    errorMessage = "No speech detected"
                    state = .idle
                    return
                }

                let entry = MarkdownFormatter.formatEntry(text: fullText, at: now)
                try noteStore.save(entry: entry, for: now)

                if activeMode == .phoneStream {
                    connector.sendRecordingComplete(date: now)
                }

                lastCaptureTimestamp = now
                lastTranscribedText = fullText
                sessionManager.stopKeepAlive()
                activeMode = nil
                state = .idle
            } catch {
                sessionManager.stopKeepAlive()
                activeMode = nil
                state = .idle
                errorMessage = "[\(type(of: error))] \(error)"
            }
        }
    }

    /// Transcribe a chunk to update the live transcript (but don't save to file yet)
    private func transcribeChunkForPreview(_ buffers: [AVAudioPCMBuffer]) {
        Task {
            guard let merged = AudioRecorder.mergeBuffers(buffers) else { return }
            do {
                let text = try await transcriptionEngine.transcribe(buffer: merged)
                await MainActor.run {
                    handleTranscriptionResult(text)
                }
            } catch {
                print("Chunk preview transcription failed: \(error)")
            }
        }
    }

    private func handleTranscriptionResult(_ text: String) {
        chunksTranscribed += 1
        lastTranscribedText = text
        if liveTranscript.isEmpty {
            liveTranscript = text
        } else {
            liveTranscript += " " + text
        }
    }
}
