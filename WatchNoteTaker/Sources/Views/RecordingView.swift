import SwiftUI
import WatchKit

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
                let wasRecording = viewModel.state == .recording
                viewModel.toggleRecording()

                // Haptic feedback
                if wasRecording {
                    WKInterfaceDevice.current().play(.stop)
                } else if viewModel.state == .recording {
                    WKInterfaceDevice.current().play(.start)
                }
            }
            .onChange(of: viewModel.state) { oldState, newState in
                if newState == .idle && viewModel.lastCaptureTimestamp != nil && viewModel.errorMessage == nil {
                    WKInterfaceDevice.current().play(.success)
                } else if newState == .idle && viewModel.errorMessage != nil {
                    WKInterfaceDevice.current().play(.failure)
                }
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
            ProcessingIndicator(existingText: viewModel.liveTranscript.isEmpty ? nil : viewModel.liveTranscript)
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
