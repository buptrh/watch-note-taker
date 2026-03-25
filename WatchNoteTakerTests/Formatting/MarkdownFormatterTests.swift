import XCTest
@testable import WatchNoteTaker

final class MarkdownFormatterTests: XCTestCase {

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

    func testFormatEntry_normalText() {
        let date = makeDate(hour: 14, minute: 30)
        let result = MarkdownFormatter.formatEntry(text: "Hello world", at: date)
        XCTAssertEqual(result, "## 14:30\n\nHello world\n\n")
    }

    func testFormatEntry_zeroPaddedTime() {
        let date = makeDate(hour: 9, minute: 5)
        let result = MarkdownFormatter.formatEntry(text: "Early", at: date)
        XCTAssertEqual(result, "## 09:05\n\nEarly\n\n")
    }

    func testFormatEntry_emptyText() {
        let date = makeDate()
        let result = MarkdownFormatter.formatEntry(text: "", at: date)
        XCTAssertEqual(result, "## 14:30\n\n\n\n")
    }

    func testFormatEntry_multilineText() {
        let date = makeDate()
        let text = "Line one\nLine two"
        let result = MarkdownFormatter.formatEntry(text: text, at: date)
        XCTAssertEqual(result, "## 14:30\n\nLine one\nLine two\n\n")
    }

    func testFormatEntry_markdownInText() {
        let date = makeDate()
        let result = MarkdownFormatter.formatEntry(text: "Use **bold** and `code`", at: date)
        XCTAssertTrue(result.contains("**bold**"))
    }

    func testGenerateFrontmatter_containsRequiredFields() {
        let date = makeDate()
        let result = MarkdownFormatter.generateFrontmatter(date: date)
        XCTAssertTrue(result.contains("type: voice-capture"))
        XCTAssertTrue(result.contains("created: 2026-03-24"))
        XCTAssertTrue(result.contains("source: apple-watch"))
        XCTAssertTrue(result.contains("tags: [inbox, voice]"))
    }

    func testGenerateFrontmatter_containsTitle() {
        let date = makeDate()
        let result = MarkdownFormatter.generateFrontmatter(date: date)
        XCTAssertTrue(result.contains("# Watch Notes — 2026-03-24"))
    }

    func testGenerateFrontmatter_endsWithNewlines() {
        let date = makeDate()
        let result = MarkdownFormatter.generateFrontmatter(date: date)
        XCTAssertTrue(result.hasSuffix("\n\n"))
    }

    func testFilename() {
        let date = makeDate()
        XCTAssertEqual(MarkdownFormatter.filename(for: date), "watch_2026-03-24.md")
    }

    func testConcatenation_frontmatterPlusEntry() {
        let date = makeDate(hour: 10, minute: 0)
        let frontmatter = MarkdownFormatter.generateFrontmatter(date: date)
        let entry = MarkdownFormatter.formatEntry(text: "First note", at: date)
        let combined = frontmatter + entry
        XCTAssertTrue(combined.hasPrefix("---"))
        XCTAssertTrue(combined.contains("## 10:00"))
        XCTAssertTrue(combined.contains("First note"))
    }
}
