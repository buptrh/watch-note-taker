import AVFoundation

/// Demo audio recorder that produces a silent buffer for simulator testing.
/// This allows the full UI pipeline to run without a real microphone.
final class SimulatorAudioRecorder: AudioRecording, @unchecked Sendable {
    private var isRecording = false

    func start() async throws {
        isRecording = true
        // Simulate recording delay
        try await Task.sleep(for: .seconds(1))
    }

    func stop() async throws -> AVAudioPCMBuffer {
        guard isRecording else {
            throw AudioRecorderError.notRecording
        }
        isRecording = false

        // Create a short silent buffer
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16000)!
        buffer.frameLength = 16000
        return buffer
    }
}
