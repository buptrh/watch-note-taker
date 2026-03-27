import AVFoundation

/// Detects silence in audio buffers and triggers chunk sends.
/// Uses energy-based VAD: when RMS drops below threshold for silenceDuration, marks a boundary.
final class VADChunker: @unchecked Sendable {

    struct Config {
        var minChunkSeconds: Double = 10
        var maxChunkSeconds: Double = 60
        var silenceThreshold: Float = 0.01
        var silenceDurationSeconds: Double = 1.5
    }

    let config: Config
    private var accumulatedBuffers: [AVAudioPCMBuffer] = []
    private var accumulatedDuration: Double = 0
    private var silenceDuration: Double = 0
    private let lock = NSLock()

    init(config: Config = Config()) {
        self.config = config
    }

    enum ChunkResult {
        case accumulating
        case chunkReady([AVAudioPCMBuffer])
    }

    /// Feed a new audio buffer. Returns .chunkReady when a chunk should be sent.
    func feed(_ buffer: AVAudioPCMBuffer) -> ChunkResult {
        lock.lock()
        defer { lock.unlock() }

        let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
        accumulatedBuffers.append(buffer)
        accumulatedDuration += bufferDuration

        let rms = calculateRMS(buffer)
        if rms < config.silenceThreshold {
            silenceDuration += bufferDuration
        } else {
            silenceDuration = 0
        }

        // Force send at max chunk size
        if accumulatedDuration >= config.maxChunkSeconds {
            return flushChunk()
        }

        // Send at silence boundary if min chunk reached
        if silenceDuration >= config.silenceDurationSeconds &&
           accumulatedDuration >= config.minChunkSeconds {
            return flushChunk()
        }

        return .accumulating
    }

    /// Force flush whatever is accumulated (e.g., when recording stops)
    func flush() -> [AVAudioPCMBuffer]? {
        lock.lock()
        defer { lock.unlock() }
        guard !accumulatedBuffers.isEmpty else { return nil }
        let buffers = accumulatedBuffers
        accumulatedBuffers = []
        accumulatedDuration = 0
        silenceDuration = 0
        return buffers
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        accumulatedBuffers = []
        accumulatedDuration = 0
        silenceDuration = 0
    }

    private func flushChunk() -> ChunkResult {
        let buffers = accumulatedBuffers
        accumulatedBuffers = []
        accumulatedDuration = 0
        silenceDuration = 0
        return .chunkReady(buffers)
    }

    private func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[0][i]
            sum += sample * sample
        }
        return sqrt(sum / Float(frameLength))
    }
}
