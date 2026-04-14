import XCTest
@testable import ShelfKit

final class ShelfItemTests: XCTestCase {

    // MARK: - File initializer

    func testFileInitSetsTypeAndSourceKind() {
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/report.pdf"), isDirectory: false)
        XCTAssertEqual(item.type, .file)
        XCTAssertEqual(item.sourceKind, .fileReference)
        XCTAssertEqual(item.displayName, "report.pdf")
        XCTAssertEqual(item.originalURL, URL(fileURLWithPath: "/tmp/report.pdf"))
    }

    func testFolderInitSetsTypeAndSourceKind() {
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/myFolder"), isDirectory: true)
        XCTAssertEqual(item.type, .folder)
        XCTAssertEqual(item.sourceKind, .fileReference)
        XCTAssertEqual(item.displayName, "myFolder")
    }

    func testFileInitWithEmptyLastPathComponent() {
        // A root URL like "/" has an empty lastPathComponent
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/"), isDirectory: true)
        XCTAssertEqual(item.displayName, "/")
    }

    // MARK: - Text initializer

    func testTextInitTrimsWhitespace() {
        let item = ShelfItem(text: "  hello world  \n")
        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.sourceKind, .plainText)
        XCTAssertEqual(item.textValue, "hello world")
        XCTAssertEqual(item.displayName, "hello world")
    }

    func testTextInitTruncatesLongPreview() {
        let longText = String(repeating: "a", count: 200)
        let item = ShelfItem(text: longText)
        XCTAssertEqual(item.displayName.count, 80)
        XCTAssertEqual(item.textValue?.count, 200)
    }

    func testTextInitEmptyStringUsesPlaceholder() {
        let item = ShelfItem(text: "   ")
        XCTAssertEqual(item.displayName, "Text Clip")
        XCTAssertEqual(item.textValue, "")
    }

    // MARK: - URL initializer

    func testURLInitWithHost() {
        let item = ShelfItem(url: URL(string: "https://example.com/path")!)
        XCTAssertEqual(item.type, .url)
        XCTAssertEqual(item.sourceKind, .webURL)
        XCTAssertEqual(item.displayName, "example.com")
        XCTAssertEqual(item.originalURL, URL(string: "https://example.com/path"))
    }

    func testURLInitWithoutHost() {
        let item = ShelfItem(url: URL(string: "data:text/plain;base64,SGVsbG8=")!)
        XCTAssertEqual(item.displayName, "data:text/plain;base64,SGVsbG8=")
    }

    // MARK: - Icon system names

    func testIconSystemNames() {
        XCTAssertEqual(ShelfItem(fileURL: URL(fileURLWithPath: "/f.txt"), isDirectory: false).iconSystemName, "doc")
        XCTAssertEqual(ShelfItem(fileURL: URL(fileURLWithPath: "/dir"), isDirectory: true).iconSystemName, "folder")
        XCTAssertEqual(ShelfItem(text: "hi").iconSystemName, "text.alignleft")
        XCTAssertEqual(ShelfItem(url: URL(string: "https://a.com")!).iconSystemName, "link")
    }

    // MARK: - Subtitle

    func testFileSubtitleShowsPath() {
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/file.txt"), isDirectory: false)
        XCTAssertEqual(item.subtitle, "/tmp/file.txt")
    }

    func testTextSubtitle() {
        let item = ShelfItem(text: "hello")
        XCTAssertEqual(item.subtitle, "Plain text")
    }

    func testURLSubtitleShowsFullURL() {
        let item = ShelfItem(url: URL(string: "https://example.com/docs")!)
        XCTAssertEqual(item.subtitle, "https://example.com/docs")
    }

    func testFileSubtitleFallbackWhenNoURL() {
        let item = ShelfItem(type: .file, sourceKind: .fileReference, displayName: "orphan.txt")
        XCTAssertEqual(item.subtitle, "Local reference")
    }

    // MARK: - isFileSystemItem

    func testIsFileSystemItem() {
        XCTAssertTrue(ShelfItem(fileURL: URL(fileURLWithPath: "/f"), isDirectory: false).isFileSystemItem)
        XCTAssertTrue(ShelfItem(fileURL: URL(fileURLWithPath: "/d"), isDirectory: true).isFileSystemItem)
        XCTAssertFalse(ShelfItem(text: "t").isFileSystemItem)
        XCTAssertFalse(ShelfItem(url: URL(string: "https://a.com")!).isFileSystemItem)
    }

    // MARK: - Identifiable / Hashable

    func testUniqueIDs() {
        let a = ShelfItem(text: "same")
        let b = ShelfItem(text: "same")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testHashable() {
        let item = ShelfItem(text: "hello")
        var set = Set<ShelfItem>()
        set.insert(item)
        set.insert(item) // duplicate
        XCTAssertEqual(set.count, 1)
    }
}
