import Foundation

enum NoteStoreError: Error, Equatable {
    case containerUnavailable
    case fileWriteFailed(String)
    case fileReadFailed(String)
}
