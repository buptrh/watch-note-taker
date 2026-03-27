import XCTest

@MainActor
final class PhoneDemoFlowTest: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
        app.launchArguments = ["--skip-onboarding"]
        app.launch()
    }

    func testFullCaptureFlow() {
        // State 1: Idle — shows title and mic button
        let title = app.staticTexts["WatchNoteTaker"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Title should appear")
        sleep(2)
        screenshot("1_Idle")

        // Tap the mic button to start recording
        let micButton = app.buttons.firstMatch
        XCTAssertTrue(micButton.waitForExistence(timeout: 5), "Mic button should exist")
        micButton.tap()
        sleep(3)
        screenshot("2_Recording")

        // Tap the stop button
        let stopButton = app.buttons.firstMatch
        stopButton.tap()
        sleep(1)
        screenshot("3_Processing")

        // Wait for transcription + save to complete
        sleep(5)
        screenshot("4_Saved")

        // Tap settings gear
        let gear = app.buttons.matching(identifier: "gearshape").firstMatch
        if gear.exists {
            gear.tap()
            sleep(2)
            screenshot("5_Settings")
        }
    }

    private func screenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
