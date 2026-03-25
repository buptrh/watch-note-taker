import SwiftUI

@main
struct WatchNoteTakerApp: App {
    @State private var viewModel = RecordingViewModel(
        audioRecorder: AudioRecorder(),
        transcriptionEngine: TranscriptionEngine(),
        noteStore: NoteStore()
    )

    var body: some Scene {
        WindowGroup {
            RecordingView(viewModel: viewModel)
                .onAppear {
                    ActionButtonIntent.viewModel = viewModel
                }
        }
    }
}
