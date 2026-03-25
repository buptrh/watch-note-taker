import Foundation

enum TranscriptionError: Error, Equatable {
    case notAvailable
    case recognitionFailed(String)
    case emptyResult
}
