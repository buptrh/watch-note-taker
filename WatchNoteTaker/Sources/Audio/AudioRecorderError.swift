import Foundation

enum AudioRecorderError: Error, Equatable {
    case microphonePermissionDenied
    case audioSessionActivationFailed(String)
    case engineStartFailed(String)
    case notRecording

    static func == (lhs: AudioRecorderError, rhs: AudioRecorderError) -> Bool {
        switch (lhs, rhs) {
        case (.microphonePermissionDenied, .microphonePermissionDenied): true
        case (.audioSessionActivationFailed(let a), .audioSessionActivationFailed(let b)): a == b
        case (.engineStartFailed(let a), .engineStartFailed(let b)): a == b
        case (.notRecording, .notRecording): true
        default: false
        }
    }
}
