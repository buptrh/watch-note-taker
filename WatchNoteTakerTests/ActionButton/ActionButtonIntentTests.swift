import XCTest
@testable import WatchNoteTaker

@MainActor
final class ActionButtonIntentTests: XCTestCase {

    override func tearDown() {
        ActionButtonIntent.viewModel = nil
        super.tearDown()
    }

    func testPerform_callsToggle() async throws {
        let mock = MockRecordingToggleable()
        ActionButtonIntent.viewModel = mock

        let intent = ActionButtonIntent()
        _ = try await intent.perform()

        XCTAssertTrue(mock.toggleCalled)
    }

    func testPerform_nilViewModel_doesNotCrash() async throws {
        ActionButtonIntent.viewModel = nil

        let intent = ActionButtonIntent()
        _ = try await intent.perform()
        // No crash = pass
    }

    func testPerform_multipleCalls() async throws {
        let mock = MockRecordingToggleable()
        ActionButtonIntent.viewModel = mock

        let intent = ActionButtonIntent()
        _ = try await intent.perform()
        _ = try await intent.perform()
        _ = try await intent.perform()

        XCTAssertEqual(mock.toggleCallCount, 3)
    }
}
