import AVFoundation
import Speech

final class TranscriptionEngine: Transcribing, @unchecked Sendable {

    private let recognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
        self.recognizer?.defaultTaskHint = .dictation
    }

    func transcribe(buffer: AVAudioPCMBuffer) async throws -> String {
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriptionError.notAvailable
        }

        let status = SFSpeechRecognizer.authorizationStatus()
        if status != .authorized {
            throw TranscriptionError.notAuthorized
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.addPreconditionCheck()

        request.append(buffer)
        request.endAudio()

        let result: String = try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            recognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }

                if let error {
                    hasResumed = true
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error.localizedDescription))
                    return
                }

                if let result, result.isFinal {
                    hasResumed = true
                    let text = result.bestTranscription.formattedString
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: TranscriptionError.emptyResult)
                    } else {
                        continuation.resume(returning: text)
                    }
                }
            }
        }

        return result
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

private extension SFSpeechAudioBufferRecognitionRequest {
    func addPreconditionCheck() {
        // Placeholder for any future pre-checks on the request
    }
}
