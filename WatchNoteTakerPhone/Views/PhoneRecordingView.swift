import SwiftUI
import UniformTypeIdentifiers

struct PhoneRecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @State private var showFolderPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                statusIcon
                statusText

                if let text = viewModel.lastTranscribedText,
                   viewModel.state == .idle,
                   viewModel.errorMessage == nil {
                    transcribedTextView(text)
                }

                if let error = viewModel.errorMessage {
                    errorView(error)
                }

                Spacer()

                recordButton
                    .padding(.bottom, 40)
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

    private func transcribedTextView(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
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
