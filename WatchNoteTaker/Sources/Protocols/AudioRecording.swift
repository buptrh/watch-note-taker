import AVFoundation

protocol AudioRecording: Sendable {
    func start() async throws
    func stop() async throws -> AVAudioPCMBuffer
}
