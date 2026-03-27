import Foundation

protocol NoteStoring: Sendable {
    func save(entry: String, for date: Date) throws
}
