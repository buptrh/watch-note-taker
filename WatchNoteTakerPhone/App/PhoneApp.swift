import SwiftUI
import AppIntents

@main
struct WatchNoteTakerPhoneApp: App {
    @State private var viewModel = RecordingViewModel(
        audioRecorder: AudioRecorder(),
        transcriptionEngine: TranscriptionEngine(),
        noteStore: NoteStore()
    )

    var body: some Scene {
        WindowGroup {
            PhoneRecordingView(viewModel: viewModel)
                .onAppear {
                    ActionButtonIntent.viewModel = viewModel
                }
                .task {
                    ActionButtonShortcutsProvider.updateAppShortcutParameters()
                    await viewModel.prewarmModel()
                }
        }
    }
}
