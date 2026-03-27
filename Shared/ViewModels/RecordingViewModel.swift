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

    private let audioRecorder: AudioRecorder
    private let transcriptionEngine: any Transcribing
    private let noteStore: any NoteStoring
    private let sessionManager = SessionManager()
    private let connector = WatchPhoneConnector.shared

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
        state = .recording

        // Decide mode at recording start
        let phoneReachable = preferPhoneRelay && connector.isReachable
        let useStreaming = phoneReachable || useLocalChunking

        if phoneReachable {
            activeMode = .phoneStream
            audioRecorder.onChunkReady = { [weak self] buffers in
                guard let data = AudioConverter.buffersToWAVData(buffers) else { return }
                // Hybrid: sendMessage if reachable, transferFile if not
                self?.connector.sendAudioChunk(data, recordingDate: Date())
                // Also transcribe locally as backup
                self?.transcribeChunkLocally(buffers)
            }
        } else if useLocalChunking {
            activeMode = .phoneChunking
            audioRecorder.onChunkReady = { [weak self] buffers in
                self?.transcribeChunkLocally(buffers)
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
        let wasStreaming = activeMode == .phoneStream || activeMode == .phoneChunking

        if wasStreaming {
            state = .saving

            Task {
                do {
                    _ = try await audioRecorder.stop()
                    audioRecorder.onChunkReady = nil

                    if activeMode == .phoneStream {
                        connector.sendRecordingComplete(date: Date())
                    }

                    // Brief pause for last chunk to process
                    try await Task.sleep(for: .milliseconds(500))

                    sessionManager.stopKeepAlive()
                    lastCaptureTimestamp = Date()
                    if !liveTranscript.isEmpty {
                        lastTranscribedText = liveTranscript
                    }
                    activeMode = nil
                    state = .idle
                } catch {
                    sessionManager.stopKeepAlive()
                    activeMode = nil
                    state = .idle
                    errorMessage = "[\(type(of: error))] \(error)"
                }
            }
        } else {
            // Full recording, transcribe at once
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
    }

    /// Transcribe a chunk locally and save
    private func transcribeChunkLocally(_ buffers: [AVAudioPCMBuffer]) {
        Task {
            guard let merged = AudioRecorder.mergeBuffers(buffers) else { return }
            do {
                let text = try await transcriptionEngine.transcribe(buffer: merged)
                let now = Date()
                let entry = MarkdownFormatter.formatEntry(text: text, at: now)
                try noteStore.save(entry: entry, for: now)
                await MainActor.run {
                    handleTranscriptionResult(text)
                }
            } catch {
                print("Chunk transcription failed: \(error)")
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
