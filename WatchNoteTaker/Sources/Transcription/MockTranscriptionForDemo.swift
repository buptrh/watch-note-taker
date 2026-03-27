import AVFoundation

/// Demo transcription engine that returns sample text for simulator testing.
/// This allows the full UI pipeline to run without WhisperKit model loading.
final class SimulatorTranscriptionEngine: Transcribing, @unchecked Sendable {

    private let sampleTexts = [
        "Remember to review the design docs for the watch app",
        "Buy groceries on the way home, eggs milk bread",
        "Idea for a new feature, auto tagging voice notes by topic",
        "Meeting with the team tomorrow at 10am about the release",
        "The quick brown fox jumps over the lazy dog",
    ]

    func prewarm() async {}

    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String {
        // Simulate transcription delay
        try await Task.sleep(for: .milliseconds(800))
        return sampleTexts.randomElement()!
    }
}
