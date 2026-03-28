import SwiftUI
import WatchKit

struct RecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var connector = WatchPhoneConnector.shared
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    private static let confirmationThreshold: TimeInterval = 5.0

    private enum DisplayState {
        case ready
        case recording
        case processing
        case confirmation
        case remoteRecording
        case error(String)
    }

    private var displayState: DisplayState {
        if let errorMessage = viewModel.errorMessage {
            return .error(errorMessage)
        }

        switch viewModel.state {
        case .idle:
            // Read directly from connector (Combine), not ViewModel (Observation)
            if connector.remoteIsRecording {
                return .remoteRecording
            }
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
        TimelineView(.periodic(from: .now, by: viewModel.state == .recording ? 1 : 60)) { _ in
            ZStack(alignment: .bottomTrailing) {
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.ink)
                    .opacity(isLuminanceReduced && viewModel.state == .idle ? 0.6 : 1.0)

                // Connection indicator — always visible, bottom-right corner
                connectionDot
                    .padding(.trailing, DS.Space.sm)
                    .padding(.bottom, DS.Space.sm)
            }
        }
        .onTapGesture {
            guard !connector.remoteIsRecording else { return }

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

    // MARK: - Connection Indicator

    private var connectionDot: some View {
        Circle()
            .fill(connector.isConnected ? DS.success : DS.slate.opacity(0.3))
            .frame(width: 6, height: 6)
    }

    // MARK: - Content

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
            ConfirmationIndicator(text: viewModel.lastTranscribedText)
        case .remoteRecording:
            PhoneRecordingIndicator()
        case .error(let message):
            ErrorIndicator(message: message)
        }
    }
}
