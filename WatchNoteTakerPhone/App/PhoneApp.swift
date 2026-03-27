import SwiftUI
import AppIntents

@main
struct WatchNoteTakerPhoneApp: App {
    @StateObject private var vaultWriter = VaultWriter()
    @StateObject private var watchService: PhoneTranscriptionService
    @State private var viewModel: RecordingViewModel?

    init() {
        let vw = VaultWriter()
        _vaultWriter = StateObject(wrappedValue: vw)
        _watchService = StateObject(wrappedValue: PhoneTranscriptionService(
            transcriptionEngine: TranscriptionEngine(),
            vaultWriter: vw,
            noteStore: NoteStore()
        ))
    }

    var body: some Scene {
        WindowGroup {
            if let viewModel {
                PhoneRecordingView(viewModel: viewModel, vaultWriter: vaultWriter, watchService: watchService)
                    .onAppear {
                        ActionButtonIntent.viewModel = viewModel
                        WatchPhoneConnector.shared.activate()
                    }
                    .task {
                        ActionButtonShortcutsProvider.updateAppShortcutParameters()
                        await viewModel.prewarmModel()
                        await watchService.prewarm()
                    }
            } else {
                ProgressView("Loading...")
                    .onAppear { setupViewModel() }
            }
        }
    }

    private func setupViewModel() {
        let store = VaultNoteStore(vaultWriter: vaultWriter)
        let vm = RecordingViewModel(
            audioRecorder: AudioRecorder(),
            transcriptionEngine: TranscriptionEngine(),
            noteStore: store
        )
        vm.useLocalChunking = true
        viewModel = vm
    }
}
