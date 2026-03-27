import SwiftUI
import UniformTypeIdentifiers

struct PhoneMainView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @ObservedObject var watchService: PhoneTranscriptionService
    @ObservedObject var history: RecordingHistory
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            PhoneRecordingView(
                viewModel: viewModel,
                vaultWriter: vaultWriter,
                watchService: watchService,
                history: history
            )
            .tabItem {
                Label("Record", systemImage: "mic.fill")
            }

            NavigationStack {
                HistoryView(history: history)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView(settings: settings, vaultWriter: vaultWriter)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct PhoneRecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @ObservedObject var watchService: PhoneTranscriptionService
    @ObservedObject var history: RecordingHistory

    private var isWatchMode: Bool {
        watchService.isWatchRecording && viewModel.state == .idle
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if isWatchMode {
                    watchRecordingView
                } else {
                    statusIcon
                    statusText

                    // Recording timer
                    if viewModel.state == .recording {
                        Text(formatDuration(viewModel.recordingDuration))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .foregroundStyle(.red)
                    }

                    // Show transcript
                    if !viewModel.liveTranscript.isEmpty || viewModel.state == .transcribing || viewModel.state == .saving {
                        transcriptArea
                    } else if viewModel.lastTranscribedText != nil,
                              viewModel.state == .idle,
                              viewModel.errorMessage == nil {
                        transcriptArea
                    }

                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }
                }

                Spacer()

                if !isWatchMode {
                    recordButton
                        .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .onChange(of: viewModel.state) { oldState, newState in
                // Save to history when recording completes
                if oldState == .saving && newState == .idle,
                   let text = viewModel.lastTranscribedText,
                   !text.isEmpty {
                    history.add(
                        text: text,
                        date: viewModel.lastCaptureTimestamp ?? Date(),
                        duration: viewModel.recordingDuration
                    )
                }
            }
        }
    }

    // MARK: - Timer formatting

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Status views

    @ViewBuilder
    private var statusIcon: some View {
        switch viewModel.state {
        case .idle:
            if viewModel.lastTranscribedText != nil && viewModel.errorMessage == nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
            }
        case .recording:
            Circle()
                .fill(.red)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(.red.opacity(0.3), lineWidth: 4)
                        .scaleEffect(1.3)
                )
        case .transcribing, .saving:
            ProgressView()
                .scaleEffect(2)
                .tint(.orange)
        }
    }

    private var statusText: some View {
        Text(statusLabel)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
    }

    private var statusLabel: String {
        switch viewModel.state {
        case .idle:
            if viewModel.lastTranscribedText != nil && viewModel.errorMessage == nil {
                return "Saved"
            }
            return "Ready"
        case .recording: return "Recording"
        case .transcribing: return "Transcribing"
        case .saving: return "Saving"
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle:
            if viewModel.lastTranscribedText != nil && viewModel.errorMessage == nil {
                return .green
            }
            return .secondary
        case .recording: return .red
        case .transcribing, .saving: return .orange
        }
    }

    // MARK: - Watch recording

    private var watchRecordingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Recording on Watch")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.orange)

            if watchService.isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Transcribing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !watchService.liveTranscript.isEmpty {
                ScrollView {
                    Text(watchService.liveTranscript)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 300)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Transcript

    private var transcriptArea: some View {
        VStack(spacing: 8) {
            ScrollView {
                Text(displayTranscript)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(maxHeight: 250)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            if viewModel.state == .transcribing || viewModel.state == .saving {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finishing transcription...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var displayTranscript: String {
        if !viewModel.liveTranscript.isEmpty {
            return viewModel.liveTranscript
        }
        return viewModel.lastTranscribedText ?? ""
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        ScrollView {
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxHeight: 100)
    }

    // MARK: - Record button

    private var recordButton: some View {
        Button {
            let wasRecording = viewModel.state == .recording
            viewModel.toggleRecording()
            // Haptic feedback
            if wasRecording {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } label: {
            Circle()
                .fill(viewModel.state == .recording ? .red : .blue)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                }
        }
        .disabled(viewModel.state == .transcribing || viewModel.state == .saving)
    }
}

/// UIKit wrapper for folder picker
struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
