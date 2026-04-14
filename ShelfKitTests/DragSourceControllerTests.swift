import AppKit
import XCTest
@testable import ShelfKit

final class DragSourceControllerTests: XCTestCase {

    // MARK: - pasteboardWriter

    func testPasteboardWriterForFileReturnsNSURL() {
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/file.txt"), isDirectory: false)
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertTrue(writer is NSURL)
    }

    func testPasteboardWriterForFolderReturnsNSURL() {
        let item = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/folder"), isDirectory: true)
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertTrue(writer is NSURL)
    }

    func testPasteboardWriterForTextReturnsNSString() {
        let item = ShelfItem(text: "hello world")
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertTrue(writer is NSString)
        XCTAssertEqual(writer as? NSString, "hello world")
    }

    func testPasteboardWriterForTextFallsBackToDisplayName() {
        let item = ShelfItem(type: .text, sourceKind: .plainText, displayName: "fallback", textValue: nil)
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertEqual(writer as? NSString, "fallback")
    }

    func testPasteboardWriterForURLReturnsNSURL() {
        let item = ShelfItem(url: URL(string: "https://example.com")!)
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertTrue(writer is NSURL)
    }

    func testPasteboardWriterForURLWithoutOriginalURLFallsBackToString() {
        let item = ShelfItem(type: .url, sourceKind: .webURL, displayName: "example.com")
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertEqual(writer as? NSString, "example.com")
    }

    func testPasteboardWriterForFileFallsBackToDisplayNameString() {
        let item = ShelfItem(type: .file, sourceKind: .fileReference, displayName: "orphan.txt")
        let writer = DragSourceController.pasteboardWriter(for: item)
        XCTAssertEqual(writer as? NSString, "orphan.txt")
    }

    // MARK: - wholeShelfExportPayload

    func testWholeShelfExportPayloadIncludesAllItems() {
        let items = [
            ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/a.txt"), isDirectory: false),
            ShelfItem(text: "clip"),
            ShelfItem(url: URL(string: "https://a.com")!)
        ]

        let payload = DragSourceController.wholeShelfExportPayload(for: items)

        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.items.count, 3)
        XCTAssertEqual(payload?.pasteboardWriters.count, 3)
        XCTAssertEqual(payload?.itemIDs, Set(items.map(\.id)))
    }

    func testWholeShelfExportPayloadReturnsNilForEmptyItems() {
        let payload = DragSourceController.wholeShelfExportPayload(for: [])
        XCTAssertNil(payload)
    }

    // MARK: - sourceOperationMask

    func testWithinApplicationMaskAllowsCopyAndMove() {
        let items = [ShelfItem(text: "hi")]
        let mask = DragSourceController.sourceOperationMask(for: items, context: .withinApplication)
        XCTAssertTrue(mask.contains(.copy))
        XCTAssertTrue(mask.contains(.move))
    }

    func testWithinApplicationMaskEmptyForNoItems() {
        let mask = DragSourceController.sourceOperationMask(for: [], context: .withinApplication)
        XCTAssertTrue(mask.isEmpty)
    }

    func testOutsideApplicationMaskCopyOnlyForTextItems() {
        let items = [ShelfItem(text: "hi")]
        let mask = DragSourceController.sourceOperationMask(for: items, context: .outsideApplication)
        XCTAssertEqual(mask, .copy)
    }

    func testOutsideApplicationMaskAllowsMoveForFileItems() {
        let items = [ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/f.txt"), isDirectory: false)]
        let mask = DragSourceController.sourceOperationMask(for: items, context: .outsideApplication)
        XCTAssertTrue(mask.contains(.copy))
        XCTAssertTrue(mask.contains(.move))
    }

    func testOutsideApplicationMaskAllowsMoveForMixedWithFile() {
        let items = [
            ShelfItem(text: "text"),
            ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/f.txt"), isDirectory: false)
        ]
        let mask = DragSourceController.sourceOperationMask(for: items, context: .outsideApplication)
        XCTAssertTrue(mask.contains(.move))
    }

    // MARK: - shouldConsumeExportedItems

    func testConsumeOnMoveOperation() {
        let result = DragSourceController.shouldConsumeExportedItems(
            after: .move,
            didLeaveApplication: false,
            exportedItemIDs: [UUID()]
        )
        XCTAssertTrue(result)
    }

    func testConsumeOnExternalDropSuccess() {
        let result = DragSourceController.shouldConsumeExportedItems(
            after: .copy,
            didLeaveApplication: true,
            exportedItemIDs: [UUID()]
        )
        XCTAssertTrue(result)
    }

    func testNoConsumeOnInternalCopy() {
        let result = DragSourceController.shouldConsumeExportedItems(
            after: .copy,
            didLeaveApplication: false,
            exportedItemIDs: [UUID()]
        )
        XCTAssertFalse(result)
    }

    func testNoConsumeWhenExportedIDsEmpty() {
        let result = DragSourceController.shouldConsumeExportedItems(
            after: .move,
            didLeaveApplication: false,
            exportedItemIDs: []
        )
        XCTAssertFalse(result)
    }

    func testNoConsumeOnExternalDropWithEmptyOperation() {
        let result = DragSourceController.shouldConsumeExportedItems(
            after: [],
            didLeaveApplication: true,
            exportedItemIDs: [UUID()]
        )
        XCTAssertFalse(result)
    }
}
