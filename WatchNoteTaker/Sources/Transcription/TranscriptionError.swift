import Foundation

enum TranscriptionError: Error, Equatable {
    case notAvailable
    case notAuthorized
    case recognitionFailed(String)
    case emptyResult
}
