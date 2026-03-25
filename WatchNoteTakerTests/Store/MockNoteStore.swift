import Foundation
@testable import WatchNoteTaker

final class MockNoteStore: NoteStoring, @unchecked Sendable {
    var saveCalled = false
    var savedEntry: String?
    var savedDate: Date?
    var errorToThrow: Error?

    func save(entry: String, for date: Date) throws {
        saveCalled = true
        savedEntry = entry
        savedDate = date
        if let error = errorToThrow { throw error }
    }
}
