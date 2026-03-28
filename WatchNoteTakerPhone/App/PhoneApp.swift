import SwiftUI
import AppIntents
import Combine

@main
struct WatchNoteTakerPhoneApp: App {
    @StateObject private var vaultWriter = VaultWriter()
    @StateObject private var watchService: PhoneTranscriptionService
    @StateObject private var history = RecordingHistory()
    @StateObject private var settings = AppSettings()
    @State private var viewModel: RecordingViewModel?
    @State private var transcriptionEngine: TranscriptionEngine?
    @State private var showOnboarding = false

    init() {
        let vw = VaultWriter()
        _vaultWriter = StateObject(wrappedValue: vw)
        _watchService = StateObject(wrappedValue: PhoneTranscriptionService(
            transcriptionEngine: TranscriptionEngine(),
            vaultWriter: vw,
            noteStore: NoteStore()
        ))
        // NOTE: Do NOT activate here. Callbacks must be registered first.
        // Activation happens in .onAppear after all @StateObject inits complete.
    }

    var body: some Scene {
        WindowGroup {
            if let viewModel {
                if showOnboarding {
                    OnboardingView(vaultWriter: vaultWriter) {
                        settings.onboardingComplete = true
                        showOnboarding = false
                    }
                } else {
                    PhoneMainView(
                        viewModel: viewModel,
                        vaultWriter: vaultWriter,
                        watchService: watchService,
                        history: history,
                        settings: settings
                    )
                    .onAppear {
                        ActionButtonIntent.viewModel = viewModel
                        WatchPhoneConnector.shared.activate()
                    }
                    .task {
                        ActionButtonShortcutsProvider.updateAppShortcutParameters()
                        // Load model in background — don't block recording
                        async let _ = viewModel.prewarmModel()
                        async let _ = watchService.prewarm()
                    }
                    .onChange(of: settings.language) { _, newLang in
                        transcriptionEngine?.language = newLang
                    }
                }
            } else {
                ZStack {
                    DS.ink.ignoresSafeArea()
                    VStack(spacing: DS.Space.md) {
                        ProgressView()
                            .tint(DS.amber)
                            .scaleEffect(1.2)
                        Text("Loading...")
                            .font(DS.Font.body(size: 15))
                            .foregroundStyle(DS.slateLight)
                    }
                }
                .onAppear { setupViewModel() }
            }
        }
    }

    private func setupViewModel() {
        let store = VaultNoteStore(vaultWriter: vaultWriter)
        let engine = TranscriptionEngine()
        engine.language = settings.language
        transcriptionEngine = engine

        let vm = RecordingViewModel(
            audioRecorder: AudioRecorder(),
            transcriptionEngine: engine,
            noteStore: store
        )
        vm.useLocalChunking = true
        viewModel = vm

        if CommandLine.arguments.contains("--skip-onboarding") {
            showOnboarding = false
        } else {
            showOnboarding = !settings.onboardingComplete
        }
    }
}
