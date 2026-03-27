import AppIntents

struct ActionButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "Voice Note"
    static let description: IntentDescription = "Start or stop voice recording on Apple Watch"
    static let openAppWhenRun: Bool = true

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
        return [
            AppShortcut(
                intent: ActionButtonIntent(),
                phrases: [
                    "Record a voice note with \(.applicationName)",
                    "Take a note with \(.applicationName)",
                    "\(.applicationName)"
                ],
                shortTitle: "Voice Note",
                systemImageName: "mic.fill"
            )
        ]
    }
}
