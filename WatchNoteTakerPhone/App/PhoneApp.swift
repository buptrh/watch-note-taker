import SwiftUI
import AppIntents

@main
struct WatchNoteTakerPhoneApp: App {
    @StateObject private var vaultWriter = VaultWriter()
    @State private var viewModel: RecordingViewModel?
    @State private var transcriptionService: PhoneTranscriptionService?

    var body: some Scene {
        WindowGroup {
            if let viewModel {
                PhoneRecordingView(viewModel: viewModel, vaultWriter: vaultWriter)
                    .onAppear {
                        ActionButtonIntent.viewModel = viewModel
                        WatchPhoneConnector.shared.activate()

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
