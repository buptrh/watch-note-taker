import AVFoundation
import WhisperKit

final class TranscriptionEngine: Transcribing, @unchecked Sendable {

    private var whisperKit: WhisperKit?
    private let modelName: String

    init(modelName: String = "openai_whisper-tiny") {
        self.modelName = modelName
    }

    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String {
        let kit = try await getOrCreateWhisperKit()

        let floatArray = bufferToFloatArray(buffer)
        guard !floatArray.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        let results = try await kit.transcribe(audioArray: floatArray)

        guard let result = results.first, !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func getOrCreateWhisperKit() async throws -> WhisperKit {
        if let existing = whisperKit {
            return existing
        }

        do {
            let kit = try await WhisperKit(model: modelName)
            whisperKit = kit
            return kit
        } catch {
            throw TranscriptionError.notAvailable
        }
    }

    private func bufferToFloatArray(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        let floats = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        return floats
    }
}
