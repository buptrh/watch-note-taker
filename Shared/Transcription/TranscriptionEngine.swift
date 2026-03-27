import AVFoundation
import WhisperKit

final class TranscriptionEngine: Transcribing, @unchecked Sendable {

    private var whisperKit: WhisperKit?

    func prewarm() async {
        _ = try? await getOrCreateWhisperKit()
    }

    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String {
        let kit = try await getOrCreateWhisperKit()

        // Normalize audio volume then save to temp file for WhisperKit
        let normalized = normalizeAudio(buffer)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
        try writeBuffer(normalized, to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Auto-detect language (supports English, Chinese, and 90+ other languages)
        let options = DecodingOptions(
            verbose: false,
            language: nil,
            detectLanguage: true,
            skipSpecialTokens: true,
            withoutTimestamps: true
        )
        let results = try await kit.transcribe(audioPath: tempURL.path, decodeOptions: options)

        guard let result = results.first,
              !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.emptyResult
        }

        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Convert any traditional Chinese characters to simplified
        return toSimplifiedChinese(text)
    }

    private func toSimplifiedChinese(_ text: String) -> String {
        let mutable = NSMutableString(string: text)
        CFStringTransform(mutable, nil, "Traditional-Simplified" as CFString, false)
        return mutable as String
    }

    private func getOrCreateWhisperKit() async throws -> WhisperKit {
        if let existing = whisperKit {
            return existing
        }

        guard let bundlePath = Bundle.main.path(forResource: "whisper-model", ofType: "bundle") else {
            throw TranscriptionError.notAvailable
        }
        let modelPath = bundlePath
        let tokenizerPath = URL(fileURLWithPath: bundlePath)
        let kit = try await WhisperKit(
            modelFolder: modelPath,
            tokenizerFolder: tokenizerPath,
            verbose: false,
            logLevel: .error,
            download: false
        )
        whisperKit = kit
        return kit
    }

    /// Normalize audio so the loudest sample reaches ~90% of full volume.
    /// This helps Whisper handle quiet recordings from the watch mic.
    private func normalizeAudio(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        guard let channelData = buffer.floatChannelData else { return buffer }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return buffer }

        // Find peak amplitude
        var peak: Float = 0
        for i in 0..<frameLength {
            let sample = abs(channelData[0][i])
            if sample > peak { peak = sample }
        }

        // Skip if already loud enough or silent
        guard peak > 0.001 else { return buffer }
        let targetPeak: Float = 0.9
        if peak >= targetPeak { return buffer }

        let gain = targetPeak / peak

        // Create a new buffer with amplified audio
        guard let normalized = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameCapacity
        ) else { return buffer }
        normalized.frameLength = buffer.frameLength

        guard let srcData = buffer.floatChannelData,
              let dstData = normalized.floatChannelData else { return buffer }

        for channel in 0..<Int(buffer.format.channelCount) {
            for i in 0..<frameLength {
                dstData[channel][i] = srcData[channel][i] * gain
            }
        }

        return normalized
    }

    private func writeBuffer(_ buffer: AVAudioPCMBuffer, to url: URL) throws {
        guard let audioFile = try? AVAudioFile(
            forWriting: url,
            settings: buffer.format.settings,
            commonFormat: buffer.format.commonFormat,
            interleaved: buffer.format.isInterleaved
        ) else {
            throw TranscriptionError.recognitionFailed("Failed to create audio file")
        }
        try audioFile.write(from: buffer)
    }
}
