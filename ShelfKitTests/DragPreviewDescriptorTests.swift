import XCTest
@testable import ShelfKit

final class DragPreviewDescriptorTests: XCTestCase {

    // MARK: - DragPreviewItem

    func testDragPreviewItemFromShelfFileItem() {
        let shelfItem = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/a.txt"), isDirectory: false)
        let preview = DragPreviewItem(item: shelfItem)
        XCTAssertEqual(preview.kind, .file)
        XCTAssertEqual(preview.title, "a.txt")
        XCTAssertEqual(preview.iconSystemName, "doc")
        XCTAssertTrue(preview.isFileSystemItem)
    }

    func testDragPreviewItemFromShelfFolderItem() {
        let shelfItem = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/dir"), isDirectory: true)
        let preview = DragPreviewItem(item: shelfItem)
        XCTAssertEqual(preview.kind, .folder)
        XCTAssertEqual(preview.iconSystemName, "folder")
        XCTAssertTrue(preview.isFileSystemItem)
    }

    func testDragPreviewItemFromShelfTextItem() {
        let shelfItem = ShelfItem(text: "hello")
        let preview = DragPreviewItem(item: shelfItem)
        XCTAssertEqual(preview.kind, .text)
        XCTAssertEqual(preview.iconSystemName, "text.alignleft")
        XCTAssertFalse(preview.isFileSystemItem)
    }

    func testDragPreviewItemFromShelfURLItem() {
        let shelfItem = ShelfItem(url: URL(string: "https://example.com")!)
        let preview = DragPreviewItem(item: shelfItem)
        XCTAssertEqual(preview.kind, .url)
        XCTAssertEqual(preview.iconSystemName, "link")
        XCTAssertFalse(preview.isFileSystemItem)
    }

    // MARK: - Descriptor from ShelfItems

    func testSingleFileDescriptor() {
        let items = [ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/notes.txt"), isDirectory: false)]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.itemCount, 1)
        XCTAssertEqual(descriptor.summaryTitle, "notes.txt")
        XCTAssertEqual(descriptor.summarySubtitle, "1 file")
        XCTAssertEqual(descriptor.primaryIconNames, ["doc"])
    }

    func testSingleTextDescriptor() {
        let items = [ShelfItem(text: "Draft")]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.itemCount, 1)
        XCTAssertEqual(descriptor.summaryTitle, "Draft")
        XCTAssertEqual(descriptor.summarySubtitle, "1 text clip")
    }

    func testSingleURLDescriptor() {
        let items = [ShelfItem(url: URL(string: "https://swift.org")!)]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.summaryTitle, "swift.org")
        XCTAssertEqual(descriptor.summarySubtitle, "1 URL")
    }

    func testMultipleItemsDescriptorShowsCount() {
        let items = [
            ShelfItem(fileURL: URL(fileURLWithPath: "/a.txt"), isDirectory: false),
            ShelfItem(text: "clip"),
            ShelfItem(url: URL(string: "https://a.com")!)
        ]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.itemCount, 3)
        XCTAssertEqual(descriptor.summaryTitle, "3 items")
        XCTAssertEqual(descriptor.summarySubtitle, "1 file • 1 text clip • 1 URL")
    }

    func testPrimaryIconNamesLimitedToThree() {
        let items = (0..<5).map { _ in ShelfItem(text: "t") }
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.primaryIconNames.count, 3)
    }

    // MARK: - Plural summaries

    func testMultipleFilesPlural() {
        let items = [
            ShelfItem(fileURL: URL(fileURLWithPath: "/a.txt"), isDirectory: false),
            ShelfItem(fileURL: URL(fileURLWithPath: "/b.txt"), isDirectory: false),
            ShelfItem(fileURL: URL(fileURLWithPath: "/dir"), isDirectory: true)
        ]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.summarySubtitle, "3 files")
    }

    func testMultipleTextClipsPlural() {
        let items = [ShelfItem(text: "a"), ShelfItem(text: "b")]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.summarySubtitle, "2 text clips")
    }

    func testMultipleURLsPlural() {
        let items = [
            ShelfItem(url: URL(string: "https://a.com")!),
            ShelfItem(url: URL(string: "https://b.com")!)
        ]
        let descriptor = DragPreviewDescriptor(items: items)

        XCTAssertEqual(descriptor.summarySubtitle, "2 URLs")
    }

    // MARK: - Placeholder

    func testPlaceholder() {
        let p = DragPreviewDescriptor.placeholder
        XCTAssertEqual(p.itemCount, 0)
        XCTAssertTrue(p.primaryIconNames.isEmpty)
        XCTAssertEqual(p.summaryTitle, "New Shelf")
        XCTAssertEqual(p.summarySubtitle, "Drop to collect")
    }

    // MARK: - Empty preview items

    func testEmptyPreviewItemsDescriptor() {
        let descriptor = DragPreviewDescriptor(previewItems: [])

        XCTAssertEqual(descriptor.itemCount, 0)
        XCTAssertEqual(descriptor.summaryTitle, "0 items")
        XCTAssertEqual(descriptor.summarySubtitle, "Drop to collect")
    }

    // MARK: - Folders counted as file-system items

    func testFoldersCountedAsFiles() {
        let items = [
            ShelfItem(fileURL: URL(fileURLWithPath: "/a"), isDirectory: true),
            ShelfItem(fileURL: URL(fileURLWithPath: "/b"), isDirectory: false)
        ]
        let descriptor = DragPreviewDescriptor(items: items)

        // Both folder and file are "file system items"
        XCTAssertEqual(descriptor.summarySubtitle, "2 files")
    }
}
