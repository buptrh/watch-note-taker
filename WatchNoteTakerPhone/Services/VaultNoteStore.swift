import Foundation

/// A NoteStoring implementation that writes to the Obsidian vault if available,
/// otherwise falls back to local storage.
final class VaultNoteStore: NoteStoring, @unchecked Sendable {

    private let vaultWriter: VaultWriter
    private let fallback: NoteStore

    init(vaultWriter: VaultWriter, fallback: NoteStore = NoteStore()) {
        self.vaultWriter = vaultWriter
        self.fallback = fallback
    }

    func save(entry: String, for date: Date) throws {
        if vaultWriter.hasVaultAccess {
            try vaultWriter.saveToVault(entry: entry, for: date)
        } else {
            try fallback.save(entry: entry, for: date)
        }
    }
}
