import Foundation

@MainActor
protocol RecordingToggleable: AnyObject {
    func toggleRecording()
}
