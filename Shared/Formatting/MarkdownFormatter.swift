import Foundation

enum MarkdownFormatter {

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func formatEntry(text: String, at date: Date) -> String {
        let time = timeFormatter.string(from: date)
        return "## \(time)\n\n\(text)\n\n"
    }

    static func generateFrontmatter(date: Date) -> String {
        let d = dateFormatter.string(from: date)
        return "---\ntype: voice-capture\ncreated: \(d)\nsource: apple-watch\ntags: [inbox, voice]\n---\n\n# Watch Notes — \(d)\n\n"
    }

    static func filename(for date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "watch_\(dateString).md"
    }
}
