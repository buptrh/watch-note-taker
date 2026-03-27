import SwiftUI

struct RecordingView: View {
    @Bindable var viewModel: RecordingViewModel

    private static let confirmationThreshold: TimeInterval = 5.0

    private enum DisplayState {
        case ready
        case recording
        case processing
        case confirmation
        case error(String)
    }

    private var displayState: DisplayState {
        if let errorMessage = viewModel.errorMessage {
            return .error(errorMessage)
        }

        switch viewModel.state {
        case .idle:
            if let lastCapture = viewModel.lastCaptureTimestamp,
               Date().timeIntervalSince(lastCapture) < Self.confirmationThreshold {
                return .confirmation
            }
            return .ready
        case .recording:
            return .recording
        case .transcribing, .saving:
            return .processing
        }
    }

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                viewModel.toggleRecording()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch displayState {
        case .ready:
            ReadyIndicator()
        case .recording:
            recordingView
        case .processing:
            ProcessingIndicator()
        case .confirmation:
            ConfirmationIndicator(text: viewModel.lastTranscribedText)
        case .error(let message):
            ErrorIndicator(message: message)
        }
    }

    private var recordingView: some View {
        ScrollView {
            VStack(spacing: 6) {
                RecordingIndicator()

                // Show active mode
                if let mode = viewModel.activeMode {
                    Text(mode.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // Show chunk count
                if viewModel.chunksTranscribed > 0 {
                    Text("\(viewModel.chunksTranscribed) chunks")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }

                // Show live transcript
                if !viewModel.liveTranscript.isEmpty {
                    Text(viewModel.liveTranscript)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 8)
        }
    }
}
