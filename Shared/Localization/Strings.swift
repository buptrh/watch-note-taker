import Foundation

/// Simple localization for key UI strings.
/// Falls back to English if the user's language isn't supported.
enum L10n {
    static var ready: String { NSLocalizedString("Ready", comment: "Idle state") }
    static var recording: String { NSLocalizedString("Recording", comment: "Recording state") }
    static var transcribing: String { NSLocalizedString("Transcribing...", comment: "Transcribing state") }
    static var saving: String { NSLocalizedString("Saving", comment: "Saving state") }
    static var saved: String { NSLocalizedString("Saved", comment: "Save complete") }
    static var noSpeech: String { NSLocalizedString("No speech detected", comment: "Empty result") }
    static var recordOnWatch: String { NSLocalizedString("Recording on Watch", comment: "Watch streaming") }
    static var history: String { NSLocalizedString("History", comment: "History tab") }
    static var settings: String { NSLocalizedString("Settings", comment: "Settings tab") }
    static var record: String { NSLocalizedString("Record", comment: "Record tab") }
    static var noRecordings: String { NSLocalizedString("No Recordings", comment: "Empty history") }
    static var voiceNotesHere: String { NSLocalizedString("Your voice notes will appear here", comment: "Empty history description") }
    static var clearAll: String { NSLocalizedString("Clear All", comment: "Clear history") }
    static var finishingTranscription: String { NSLocalizedString("Finishing transcription...", comment: "Post-recording processing") }
    static var getStarted: String { NSLocalizedString("Get Started", comment: "Onboarding") }
    static var micAccess: String { NSLocalizedString("Microphone Access", comment: "Onboarding") }
    static var grantMic: String { NSLocalizedString("Grant Microphone Access", comment: "Onboarding") }
    static var micGranted: String { NSLocalizedString("Microphone access granted!", comment: "Onboarding") }
    static var obsidianVault: String { NSLocalizedString("Obsidian Vault", comment: "Settings/Onboarding") }
    static var selectVaultFolder: String { NSLocalizedString("Select Vault Folder", comment: "Settings") }
    static var skipSetupLater: String { NSLocalizedString("Skip — I'll set up later", comment: "Onboarding") }
    static var continueButton: String { NSLocalizedString("Continue", comment: "Onboarding") }
    static var done: String { NSLocalizedString("Done", comment: "Onboarding") }

    // New strings for design system v1
    static var tapToRecord: String { NSLocalizedString("Tap to record", comment: "Idle prompt") }
    static var tapToStop: String { NSLocalizedString("Tap to stop", comment: "Recording prompt") }
    static var savedToVault: String { NSLocalizedString("Saved to vault", comment: "Confirmation") }
    static var speakItSaved: String { NSLocalizedString("Speak it. It's saved.", comment: "Tagline") }
}
