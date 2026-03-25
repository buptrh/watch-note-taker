import XCTest

@MainActor
final class DemoFlowTest: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
        app.launch()
    }

    func testFullCaptureFlow() {
        // State 1: Ready
        let readyText = app.staticTexts["Ready"]
        XCTAssertTrue(readyText.waitForExistence(timeout: 5))
        let screenshot1 = XCUIScreen.main.screenshot()
        let attach1 = XCTAttachment(screenshot: screenshot1)
        attach1.name = "1_Ready"
        attach1.lifetime = .keepAlways
        add(attach1)

        // Tap to start recording
        app.tap()
        sleep(1)

        // State 2: Recording
        let screenshot2 = XCUIScreen.main.screenshot()
        let attach2 = XCTAttachment(screenshot: screenshot2)
        attach2.name = "2_Recording"
        attach2.lifetime = .keepAlways
        add(attach2)

        // Tap to stop recording
        app.tap()
        sleep(1)

        // State 3: Processing
        let screenshot3 = XCUIScreen.main.screenshot()
        let attach3 = XCTAttachment(screenshot: screenshot3)
        attach3.name = "3_Processing"
        attach3.lifetime = .keepAlways
        add(attach3)

        // Wait for transcription + save to complete
        sleep(3)

        // State 4: Done (back to Ready, possibly with confirmation)
        let screenshot4 = XCUIScreen.main.screenshot()
        let attach4 = XCTAttachment(screenshot: screenshot4)
        attach4.name = "4_Done"
        attach4.lifetime = .keepAlways
        add(attach4)
    }
}
