import SwiftUI
import WatchKit

struct RecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

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

    private var currentFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "watch_\(formatter.string(from: Date())).md"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: viewModel.state == .recording ? 1 : 60)) { _ in
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.ink)
                .opacity(isLuminanceReduced && viewModel.state == .idle ? 0.6 : 1.0)
        }
        .onTapGesture {
            let wasRecording = viewModel.state == .recording
            viewModel.toggleRecording()

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
            RecordingIndicator(
                duration: viewModel.recordingDuration,
                liveTranscript: viewModel.liveTranscript
            )
        case .processing:
            ProcessingIndicator(
                existingText: viewModel.liveTranscript.isEmpty ? nil : viewModel.liveTranscript,
                isModelReady: viewModel.isModelReady
            )
        case .confirmation:
            ConfirmationIndicator(
                text: viewModel.lastTranscribedText,
                filename: currentFilename
            )
        case .error(let message):
            ErrorIndicator(message: message)
        }
    }
}
