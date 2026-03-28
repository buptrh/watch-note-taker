import XCTest
@testable import WatchNoteTaker

@MainActor
final class RecordingViewModelTests: XCTestCase {

    private var mockRecorder: MockAudioRecorder!
    private var mockTranscriber: MockTranscriptionEngine!
    private var mockStore: MockNoteStore!
    private var sut: RecordingViewModel!

    override func setUp() {
        super.setUp()
        mockRecorder = MockAudioRecorder()
        mockRecorder.bufferToReturn = MockAudioRecorder.makeTestBuffer()
        mockTranscriber = MockTranscriptionEngine()
        mockStore = MockNoteStore()
        sut = RecordingViewModel(
            audioRecorder: mockRecorder,
            transcriptionEngine: mockTranscriber,
            noteStore: mockStore
        )
    }

    func testInitialState() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.lastCaptureTimestamp)
        XCTAssertEqual(sut.liveTranscript, "")
        XCTAssertEqual(sut.recordingDuration, 0)
    }

    func testToggle_startsRecording() {
        sut.toggleRecording()
        XCTAssertEqual(sut.state, .recording)
    }

    func testToggle_whileRecording_beginsTranscription() async throws {
        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        XCTAssertEqual(sut.state, .transcribing)
    }

    func testHappyPath_completesFullCycle() async throws {
        mockTranscriber.textToReturn = "Hello world"

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        // Wait for transcription + save pipeline
        try await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNotNil(sut.lastCaptureTimestamp)
        XCTAssertTrue(mockStore.saveCalled)
        XCTAssertTrue(mockStore.savedEntry?.contains("Hello world") == true)
        XCTAssertEqual(sut.liveTranscript, "Hello world")
    }

    func testAudioStartError_returnsToIdle() async throws {
        mockRecorder.startError = AudioRecorderError.microphonePermissionDenied

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(sut.state, .idle)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testAudioStopError_returnsToIdle() async throws {
        mockRecorder.stopError = AudioRecorderError.notRecording
        mockRecorder.bufferToReturn = nil

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(sut.state, .idle)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testTranscriptionError_returnsToIdle() async throws {
        mockTranscriber.errorToThrow = TranscriptionError.emptyResult

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(sut.state, .idle)
        // Empty result is now a gentle confirmation, not an error
        XCTAssertNotNil(sut.lastTranscribedText)
    }

    func testSaveError_returnsToIdle() async throws {
        mockStore.errorToThrow = NoteStoreError.containerUnavailable

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(sut.state, .idle)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testToggle_ignoredDuringTranscribing() async throws {
        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        XCTAssertEqual(sut.state, .transcribing)

        // Try toggling again during transcribing — should be ignored
        sut.toggleRecording()
        XCTAssertEqual(sut.state, .transcribing)
    }

    func testErrorClears_onNextToggle() async throws {
        mockRecorder.startError = AudioRecorderError.microphonePermissionDenied
        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNotNil(sut.errorMessage)

        mockRecorder.startError = nil
        sut.toggleRecording()
        XCTAssertNil(sut.errorMessage)
    }

    func testNoSpeechDetected_showsMessage() async throws {
        mockTranscriber.textToReturn = ""
        mockTranscriber.errorToThrow = TranscriptionError.emptyResult

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))

        sut.toggleRecording()
        try await Task.sleep(for: .milliseconds(500))

        XCTAssertEqual(sut.state, .idle)
        // Empty result shown as confirmation, not error
        XCTAssertNotNil(sut.lastTranscribedText)
        XCTAssertNil(sut.errorMessage)
    }
}
