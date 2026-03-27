import Foundation
import SwiftUI

/// Writes notes directly to the Obsidian vault via a user-selected folder bookmark.
/// First use: presents a document picker to select the vault's 00_inbox/ folder.
/// Subsequent uses: accesses the bookmarked folder directly.
final class VaultWriter: ObservableObject, @unchecked Sendable {

    @Published var hasVaultAccess: Bool = false
    @Published var vaultPath: String = ""

    private let bookmarkKey = "obsidianVaultBookmark"
    private let fileManager = FileManager.default

    init() {
        hasVaultAccess = loadBookmark() != nil
        if let url = loadBookmark() {
            vaultPath = url.lastPathComponent
        }
    }

    /// Save an entry to the vault's daily file
    func saveToVault(entry: String, for date: Date) throws {
        guard let folderURL = loadBookmark() else {
            throw NoteStoreError.containerUnavailable
        }

        guard folderURL.startAccessingSecurityScopedResource() else {
            throw NoteStoreError.containerUnavailable
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let filename = MarkdownFormatter.filename(for: date)
        let fileURL = folderURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            let existing = try String(contentsOf: fileURL, encoding: .utf8)
            let updated = existing + entry
            try updated.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            let frontmatter = MarkdownFormatter.generateFrontmatter(date: date)
            let content = frontmatter + entry
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Store a security-scoped bookmark from a document picker result
    func saveBookmark(for url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            DispatchQueue.main.async {
                self.hasVaultAccess = true
                self.vaultPath = url.lastPathComponent
            }
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }

    /// Remove vault access
    func removeBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        DispatchQueue.main.async {
            self.hasVaultAccess = false
            self.vaultPath = ""
        }
    }

    private func loadBookmark() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Re-save bookmark
                saveBookmark(for: url)
            }

            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
}
