import AVFoundation

/// Converts audio buffers to/from Data for WatchConnectivity transfer.
enum AudioConverter {

    /// Convert an array of PCM buffers into WAV file data
    static func buffersToWAVData(_ buffers: [AVAudioPCMBuffer]) -> Data? {
        guard let merged = AudioRecorder.mergeBuffers(buffers) else { return nil }
        return bufferToWAVData(merged)
    }

    /// Convert a single PCM buffer into WAV file data
    static func bufferToWAVData(_ buffer: AVAudioPCMBuffer) -> Data? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".wav")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        do {
            let audioFile = try AVAudioFile(
                forWriting: tempURL,
                settings: buffer.format.settings,
                commonFormat: buffer.format.commonFormat,
                interleaved: buffer.format.isInterleaved
            )
            try audioFile.write(from: buffer)
            return try Data(contentsOf: tempURL)
        } catch {
            return nil
        }
    }

    /// Save WAV data to a temporary file and return the URL
    static func wavDataToTempFile(_ data: Data) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".wav")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}
