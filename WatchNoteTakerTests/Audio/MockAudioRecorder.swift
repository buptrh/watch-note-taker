import AVFoundation
@testable import WatchNoteTaker

/// Mock AudioRecorder for testing — overrides start/stop without actual audio hardware
final class MockAudioRecorder: AudioRecorder {
    var startCalled = false
    var stopCalled = false
    var startError: Error?
    var stopError: Error?
    var bufferToReturn: AVAudioPCMBuffer?

    override func start(streaming: Bool = false) async throws {
        startCalled = true
        if let error = startError { throw error }
    }

    override func start() async throws {
        try await start(streaming: false)
    }

    override func stop() async throws -> AVAudioPCMBuffer {
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
