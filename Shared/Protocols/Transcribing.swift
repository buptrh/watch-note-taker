import AVFoundation

protocol Transcribing: Sendable {
    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String
    func prewarm() async
    var isModelReady: Bool { get }
}
