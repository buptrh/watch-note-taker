import XCTest
@testable import WatchNoteTaker

final class NoteStoreTests: XCTestCase {

    private var tempDir: URL!
    private var sut: TestableNoteStore!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        sut = TestableNoteStore(testDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeDate(year: Int = 2026, month: Int = 3, day: Int = 24,
                          hour: Int = 14, minute: Int = 30) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    func testSave_createsNewFile() throws {
        let date = makeDate()
        let entry = MarkdownFormatter.formatEntry(text: "Hello", at: date)
        try sut.save(entry: entry, for: date)

        let fileURL = tempDir.appendingPathComponent("00_inbox/watch_2026-03-24.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("type: voice-capture"))
        XCTAssertTrue(content.contains("## 14:30"))
        XCTAssertTrue(content.contains("Hello"))
    }

    func testSave_appendsToExistingFile() throws {
        let date1 = makeDate(hour: 10, minute: 0)
        let entry1 = MarkdownFormatter.formatEntry(text: "First", at: date1)
        try sut.save(entry: entry1, for: date1)

        let date2 = makeDate(hour: 14, minute: 30)
        let entry2 = MarkdownFormatter.formatEntry(text: "Second", at: date2)
        try sut.save(entry: entry2, for: date2)

        let fileURL = tempDir.appendingPathComponent("00_inbox/watch_2026-03-24.md")
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(content.contains("## 10:00"))
        XCTAssertTrue(content.contains("First"))
        XCTAssertTrue(content.contains("## 14:30"))
        XCTAssertTrue(content.contains("Second"))
    }

    func testSave_createsInboxDirectory() throws {
        let date = makeDate()
        let entry = MarkdownFormatter.formatEntry(text: "Test", at: date)
        try sut.save(entry: entry, for: date)

        let inboxURL = tempDir.appendingPathComponent("00_inbox")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: inboxURL.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testSave_differentDays_createsSeparateFiles() throws {
        let date1 = makeDate(day: 24)
        let entry1 = MarkdownFormatter.formatEntry(text: "Day one", at: date1)
        try sut.save(entry: entry1, for: date1)

        let date2 = makeDate(day: 25)
        let entry2 = MarkdownFormatter.formatEntry(text: "Day two", at: date2)
        try sut.save(entry: entry2, for: date2)

        let file1 = tempDir.appendingPathComponent("00_inbox/watch_2026-03-24.md")
        let file2 = tempDir.appendingPathComponent("00_inbox/watch_2026-03-25.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path))
    }

    func testSave_frontmatterOnlyOnFirstEntry() throws {
        let date = makeDate(hour: 10)
        let entry = MarkdownFormatter.formatEntry(text: "First", at: date)
        try sut.save(entry: entry, for: date)

        let date2 = makeDate(hour: 11)
        let entry2 = MarkdownFormatter.formatEntry(text: "Second", at: date2)
        try sut.save(entry: entry2, for: date2)

        let fileURL = tempDir.appendingPathComponent("00_inbox/watch_2026-03-24.md")
        let content = try String(contentsOf: fileURL, encoding: .utf8)

        let frontmatterCount = content.components(separatedBy: "type: voice-capture").count - 1
        XCTAssertEqual(frontmatterCount, 1)
    }
}

/// A testable NoteStore that writes to a local temp directory instead of iCloud
final class TestableNoteStore: NoteStoring {
    private let testDirectory: URL
    private let fileManager = FileManager.default

    init(testDirectory: URL) {
        self.testDirectory = testDirectory
    }

    func save(entry: String, for date: Date) throws {
        let inboxURL = testDirectory.appendingPathComponent("00_inbox", isDirectory: true)

        if !fileManager.fileExists(atPath: inboxURL.path) {
            try fileManager.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        }

        let filename = MarkdownFormatter.filename(for: date)
        let fileURL = inboxURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            let existing = try String(contentsOf: fileURL, encoding: .utf8)
            let updated = existing + entry
            try updated.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            let frontmatter = MarkdownFormatter.generateFrontmatter(date: date)
            let content = frontmatter + entry
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
}
