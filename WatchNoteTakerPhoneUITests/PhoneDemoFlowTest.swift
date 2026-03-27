import XCTest

@MainActor
final class PhoneDemoFlowTest: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
    }

    // MARK: - Test 1: Onboarding Flow

    func testOnboardingFlow() {
        // Launch WITHOUT skip-onboarding to see the onboarding
        app.launch()

        // Step 1: Welcome screen
        let title = app.staticTexts["WatchNoteTaker"]
        if title.waitForExistence(timeout: 5) {
            sleep(2)
            screenshot("onboarding_1_welcome")

            // Tap "Get Started"
            let getStarted = app.buttons["Get Started"]
            if getStarted.exists {
                getStarted.tap()
                sleep(2)
                screenshot("onboarding_2_microphone")

                // Handle mic permission - tap the button
                let micButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Microphone' OR label CONTAINS 'Continue'")).firstMatch
                if micButton.waitForExistence(timeout: 3) {
                    micButton.tap()
                    sleep(1)
                    // If system dialog appears, allow it
                    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                    let allowButton = springboard.buttons["Allow"]
                    if allowButton.waitForExistence(timeout: 3) {
                        allowButton.tap()
                    }
                    sleep(2)
                    screenshot("onboarding_3_mic_granted")

                    // Should auto-advance or tap Continue
                    let continueBtn = app.buttons["Continue"]
                    if continueBtn.waitForExistence(timeout: 3) {
                        continueBtn.tap()
                    }
                    sleep(2)
                    screenshot("onboarding_4_save_location")

                    // Skip folder selection
                    let skipBtn = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch
                    if skipBtn.waitForExistence(timeout: 3) {
                        skipBtn.tap()
                        sleep(2)
                        screenshot("onboarding_5_main_screen")
                    }
                }
            }
        }
    }

    // MARK: - Test 2: Settings Page

    func testSettingsFlow() {
        app.launchArguments = ["--skip-onboarding"]
        app.launch()

        // Wait for main screen
        let title = app.staticTexts["WatchNoteTaker"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        sleep(2)
        screenshot("settings_0_main_screen")

        // Tap settings gear
        let gear = app.buttons["settingsButton"]
        if gear.waitForExistence(timeout: 5) {
            gear.tap()
            sleep(2)
            screenshot("settings_1_settings_page")

            // Scroll down to see all sections
            app.swipeUp()
            sleep(1)
            screenshot("settings_2_settings_scrolled")

            // Go back
            let back = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back'")).firstMatch
            if back.exists {
                back.tap()
                sleep(1)
                screenshot("settings_3_back_to_main")
            }
        }
    }

    // MARK: - Test 3: Full Recording Flow

    func testFullRecordingFlow() {
        app.launchArguments = ["--skip-onboarding"]
        app.launch()

        // Idle state
        let title = app.staticTexts["WatchNoteTaker"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        sleep(2)
        screenshot("recording_1_idle")

        // Tap mic button to start recording
        let micButton = app.buttons.firstMatch
        XCTAssertTrue(micButton.waitForExistence(timeout: 5))
        micButton.tap()
        sleep(1)
        screenshot("recording_2_recording_start")

        // Let it record for a few seconds
        sleep(3)
        screenshot("recording_3_recording_mid")

        // Tap stop
        let stopButton = app.buttons.firstMatch
        stopButton.tap()
        sleep(1)
        screenshot("recording_4_processing")

        // Wait for transcription + save
        sleep(5)
        screenshot("recording_5_saved")

        // Wait for it to return to idle
        sleep(6)
        screenshot("recording_6_back_to_idle")
    }

    // MARK: - Helpers

    private func screenshot(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
