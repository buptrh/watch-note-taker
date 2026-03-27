import Foundation

final class NoteStore: NoteStoring, @unchecked Sendable {

    private let containerIdentifier: String
    private let fileManager = FileManager.default

    init(containerIdentifier: String = "iCloud.com.watchnotetaker") {
        self.containerIdentifier = containerIdentifier
    }

    func save(entry: String, for date: Date) throws {
        let containerURL = try resolveContainer()
        let inboxURL = containerURL.appendingPathComponent("00_inbox", isDirectory: true)

        if !fileManager.fileExists(atPath: inboxURL.path) {
            try fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        }

        let filename = MarkdownFormatter.filename(for: date)
        let fileURL = inboxURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            try appendToFile(entry: entry, at: fileURL)
        } else {
            try createNewFile(entry: entry, date: date, at: fileURL)
        }
    }

    private func resolveContainer() throws -> URL {
        // Try iCloud first, fall back to local storage
        if let url = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) {
            let documentsURL = url.appendingPathComponent("Documents", isDirectory: true)
            if !fileManager.fileExists(atPath: documentsURL.path) {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            }
            return documentsURL
        }

        // No iCloud — use local documents directory
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NoteStoreError.containerUnavailable
        }
        return documentsURL
    }

    private func createNewFile(entry: String, date: Date, at url: URL) throws {
        let frontmatter = MarkdownFormatter.generateFrontmatter(date: date)
        let content = frontmatter + entry

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw NoteStoreError.fileWriteFailed(error.localizedDescription)
        }
    }

    private func appendToFile(entry: String, at url: URL) throws {
        let existing: String
        do {
            existing = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw NoteStoreError.fileReadFailed(error.localizedDescription)
        }

        let updated = existing + entry

        do {
            try updated.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw NoteStoreError.fileWriteFailed(error.localizedDescription)
        }
    }
}
