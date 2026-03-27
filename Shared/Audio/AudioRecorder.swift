import AVFoundation

final class AudioRecorder: AudioRecording, @unchecked Sendable {

    private let engine = AVAudioEngine()
    private let bufferQueue = DispatchQueue(label: "com.watchnotetaker.audiobuffer")
    private var accumulatedBuffers: [AVAudioPCMBuffer] = []
    private var isCurrentlyRecording = false

    func start() async throws {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            throw AudioRecorderError.audioSessionActivationFailed(error.localizedDescription)
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        bufferQueue.sync {
            accumulatedBuffers.removeAll()
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.bufferQueue.sync {
                self.accumulatedBuffers.append(buffer)
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isCurrentlyRecording = true
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioRecorderError.engineStartFailed(error.localizedDescription)
        }
    }

    func stop() async throws -> AVAudioPCMBuffer {
        guard isCurrentlyRecording else {
            throw AudioRecorderError.notRecording
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isCurrentlyRecording = false

        let buffers = bufferQueue.sync { accumulatedBuffers }

        guard let merged = mergeBuffers(buffers) else {
            throw AudioRecorderError.notRecording
        }

        return merged
    }

    private func mergeBuffers(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard let first = buffers.first else { return nil }

        let totalFrames = buffers.reduce(0) { $0 + $1.frameLength }
        guard let merged = AVAudioPCMBuffer(
            pcmFormat: first.format,
            frameCapacity: totalFrames
        ) else { return nil }

        var offset: AVAudioFrameCount = 0
        for buffer in buffers {
            let frames = buffer.frameLength
            guard let src = buffer.floatChannelData,
                  let dst = merged.floatChannelData else { continue }
            for channel in 0..<Int(buffer.format.channelCount) {
                dst[channel].advanced(by: Int(offset))
                    .update(from: src[channel], count: Int(frames))
            }
            offset += frames
        }
        merged.frameLength = totalFrames

        return merged
    }
}
