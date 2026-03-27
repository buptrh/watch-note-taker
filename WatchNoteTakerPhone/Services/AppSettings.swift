import Foundation

/// Persisted app settings
@MainActor
final class AppSettings: ObservableObject {

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: "transcriptionLanguage") }
    }

    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }

    static let supportedLanguages: [(code: String, name: String)] = [
        ("auto", "Auto Detect"),
        ("zh", "Chinese (中文)"),
        ("en", "English"),
        ("ja", "Japanese (日本語)"),
        ("ko", "Korean (한국어)"),
        ("es", "Spanish (Español)"),
        ("fr", "French (Français)"),
        ("de", "German (Deutsch)"),
        ("pt", "Portuguese (Português)"),
        ("ru", "Russian (Русский)"),
        ("ar", "Arabic (العربية)"),
        ("hi", "Hindi (हिन्दी)"),
        ("it", "Italian (Italiano)"),
        ("nl", "Dutch (Nederlands)"),
        ("pl", "Polish (Polski)"),
        ("tr", "Turkish (Türkçe)"),
        ("vi", "Vietnamese (Tiếng Việt)"),
        ("th", "Thai (ไทย)"),
        ("id", "Indonesian (Bahasa)"),
    ]

    init() {
        self.language = UserDefaults.standard.string(forKey: "transcriptionLanguage") ?? "auto"
        self.onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
}
