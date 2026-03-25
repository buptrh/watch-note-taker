import SwiftUI

struct RecordingView: View {
    @Bindable var viewModel: RecordingViewModel

    private static let confirmationThreshold: TimeInterval = 1.5

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
            RecordingIndicator()
        case .processing:
            ProcessingIndicator()
        case .confirmation:
            ConfirmationIndicator()
        case .error(let message):
            ErrorIndicator(message: message)
        }
    }
}
