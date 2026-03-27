import SwiftUI
import AppIntents

@main
struct WatchNoteTakerPhoneApp: App {
    @State private var viewModel: RecordingViewModel
    @StateObject private var vaultWriter = VaultWriter()
    @State private var transcriptionService: PhoneTranscriptionService?

    init() {
        let recorder = AudioRecorder()
        let engine = TranscriptionEngine()
        let store = NoteStore()
        _viewModel = State(initialValue: RecordingViewModel(
            audioRecorder: recorder,
            transcriptionEngine: engine,
            noteStore: store
        ))
    }

    var body: some Scene {
        WindowGroup {
            PhoneRecordingView(viewModel: viewModel, vaultWriter: vaultWriter)
                .onAppear {
                    ActionButtonIntent.viewModel = viewModel
                    WatchPhoneConnector.shared.activate()

                    // Set up watch relay service
                    if transcriptionService == nil {
                        transcriptionService = PhoneTranscriptionService(
                            transcriptionEngine: TranscriptionEngine(),
                            vaultWriter: vaultWriter,
                            noteStore: NoteStore()
                        )
                    }
                }
                .task {
                    ActionButtonShortcutsProvider.updateAppShortcutParameters()
                    await viewModel.prewarmModel()
                    await transcriptionService?.prewarm()
                }
        }
    }
}
