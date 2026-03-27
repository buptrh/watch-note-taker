import AVFoundation
@testable import WatchNoteTaker

final class MockTranscriptionEngine: Transcribing, @unchecked Sendable {
    var transcribeCalled = false
    var receivedBuffer: AVAudioPCMBuffer?
    var textToReturn: String = "Test transcription"
    var errorToThrow: Error?

    var isModelReady: Bool { true }

    func prewarm() async {}

    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String {
        transcribeCalled = true
        receivedBuffer = buffer
        if let error = errorToThrow { throw error }
        return textToReturn
    }
}
