import Foundation

struct RecordingEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let text: String
    let duration: TimeInterval
    let source: String  // "phone" or "watch"

    init(date: Date, text: String, duration: TimeInterval, source: String = "phone") {
        self.id = UUID()
        self.date = date
        self.text = text
        self.duration = duration
        self.source = source
    }
}

/// Stores recording history in UserDefaults for the phone app
@MainActor
final class RecordingHistory: ObservableObject {

    @Published var entries: [RecordingEntry] = []

    private let storageKey = "recordingHistory"
    private let maxEntries = 200

    init() {
        load()
    }

    func add(text: String, date: Date, duration: TimeInterval, source: String = "phone") {
        let entry = RecordingEntry(date: date, text: text, duration: duration, source: source)
        entries.insert(entry, at: 0)

        // Trim old entries
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([RecordingEntry].self, from: data) else { return }
        entries = decoded
    }
}
