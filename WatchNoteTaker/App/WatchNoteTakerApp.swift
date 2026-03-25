import SwiftUI

@main
struct WatchNoteTakerApp: App {
    @State private var viewModel = RecordingViewModel(
        audioRecorder: WatchNoteTakerApp.makeAudioRecorder(),
        transcriptionEngine: WatchNoteTakerApp.makeTranscriptionEngine(),
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

    private static func makeAudioRecorder() -> any AudioRecording {
        #if targetEnvironment(simulator)
        SimulatorAudioRecorder()
        #else
        AudioRecorder()
        #endif
    }

    private static func makeTranscriptionEngine() -> any Transcribing {
        #if targetEnvironment(simulator)
        SimulatorTranscriptionEngine()
        #else
        TranscriptionEngine()
        #endif
    }
}
