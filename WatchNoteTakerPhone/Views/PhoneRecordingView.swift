import SwiftUI
import UniformTypeIdentifiers

struct PhoneRecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @ObservedObject var watchService: PhoneTranscriptionService
    @State private var showFolderPicker = false

    /// True when watching a watch recording (not recording locally)
    private var isWatchMode: Bool {
        watchService.isWatchRecording && viewModel.state == .idle
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                if isWatchMode {
                    watchRecordingView
                } else {
                    statusIcon
                    statusText

                    // Show transcript: live during recording, with spinner when processing, scrollable when done
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
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if vaultWriter.hasVaultAccess {
                            Label("Vault: \(vaultWriter.vaultPath)", systemImage: "checkmark.circle.fill")
                            Button("Change Vault Folder") { showFolderPicker = true }
                            Button("Remove Vault Access", role: .destructive) { vaultWriter.removeBookmark() }
                        } else {
                            Button("Set Obsidian Vault Folder") { showFolderPicker = true }
                        }
                    } label: {
                        Image(systemName: vaultWriter.hasVaultAccess ? "folder.fill" : "folder.badge.questionmark")
                    }
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPicker { url in
                    vaultWriter.saveBookmark(for: url)
                }
            }
        }
    }

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
            .frame(maxHeight: 300)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Show processing indicator when still transcribing
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

    private var recordButton: some View {
        Button {
            viewModel.toggleRecording()
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
