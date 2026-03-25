import AppIntents

struct ActionButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Voice Recording"
    static let description: IntentDescription = "Start or stop voice recording on Apple Watch"

    @MainActor
    static var viewModel: RecordingToggleable?

    @MainActor
    func perform() async throws -> some IntentResult {
        ActionButtonIntent.viewModel?.toggleRecording()
        return .result()
    }
}

struct ActionButtonShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ActionButtonIntent(),
            phrases: ["Record a voice note with \(.applicationName)"],
            shortTitle: "Voice Note",
            systemImageName: "mic.fill"
        )
    }
}
