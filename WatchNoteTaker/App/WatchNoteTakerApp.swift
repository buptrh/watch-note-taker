import SwiftUI
import AppIntents

@main
struct WatchNoteTakerApp: App {
    @State private var viewModel: RecordingViewModel

    init() {
        let recorder = AudioRecorder()
        let engine: any Transcribing
        #if targetEnvironment(simulator)
        engine = SimulatorTranscriptionEngine()
        #else
        engine = TranscriptionEngine()
        #endif
        let store = NoteStore()
        let vm = RecordingViewModel(
            audioRecorder: recorder,
            transcriptionEngine: engine,
            noteStore: store
        )
        // Prefer phone relay if available, falls back to local automatically
        vm.preferPhoneRelay = true
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            RecordingView(viewModel: viewModel)
                .onAppear {
                    ActionButtonIntent.viewModel = viewModel
                    WatchPhoneConnector.shared.activate()
                }
                .task {
                    ActionButtonShortcutsProvider.updateAppShortcutParameters()
                    // Only prewarm local model if phone isn't reachable
                    if !WatchPhoneConnector.shared.isConnected {
                        await viewModel.prewarmModel()
                    }
                }
        }
    }
}
