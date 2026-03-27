import SwiftUI

struct PhoneRecordingView: View {
    @Bindable var viewModel: RecordingViewModel

    var body: some View {
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
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
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
