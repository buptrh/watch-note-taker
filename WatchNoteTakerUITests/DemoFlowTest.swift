import XCTest

@MainActor
final class DemoFlowTest: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
        app.launch()
    }

    func testFullCaptureFlow() {
        // State 1: Idle — shows "WatchNote" and "Press Action Button"
        let readyText = app.staticTexts["WatchNote"]
        XCTAssertTrue(readyText.waitForExistence(timeout: 5))
        sleep(1)
        screenshot("1_Ready")

        // Tap to start recording
        app.tap()
        sleep(2)
        screenshot("2_Recording")

        // Tap to stop — triggers transcription + save
        app.tap()
        sleep(1)
        screenshot("3_Processing")

        // Wait for pipeline to complete and show saved text
        sleep(3)
        screenshot("4_Saved")

        // Wait a bit more to show text is visible
        sleep(2)
        screenshot("5_SavedWithText")
    }

    private func screenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
