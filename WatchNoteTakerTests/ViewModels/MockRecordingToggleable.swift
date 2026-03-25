import Foundation
@testable import WatchNoteTaker

@MainActor
final class MockRecordingToggleable: RecordingToggleable {
    var toggleCalled = false
    var toggleCallCount = 0

    func toggleRecording() {
        toggleCalled = true
        toggleCallCount += 1
    }
}
