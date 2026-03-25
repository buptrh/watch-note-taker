import AVFoundation
@testable import WatchNoteTaker

final class MockAudioRecorder: AudioRecording, @unchecked Sendable {
    var startCalled = false
    var stopCalled = false
    var startError: Error?
    var stopError: Error?
    var bufferToReturn: AVAudioPCMBuffer?

    func start() async throws {
        startCalled = true
        if let error = startError { throw error }
    }

    func stop() async throws -> AVAudioPCMBuffer {
        stopCalled = true
        if let error = stopError { throw error }
        guard let buffer = bufferToReturn else {
            throw AudioRecorderError.notRecording
        }
        return buffer
    }

    static func makeTestBuffer(frameCount: AVAudioFrameCount = 1024) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        return buffer
    }
}
