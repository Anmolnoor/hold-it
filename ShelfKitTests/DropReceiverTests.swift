import AppKit
import SwiftUI
import XCTest
@testable import ShelfKit

@MainActor
final class DropReceiverTests: XCTestCase {

    // MARK: - canRead

    func testCanReadReturnsTrueForFileURL() {
        let pb = makePasteboard(items: [
            [.fileURL: "file:///tmp/test.txt"]
        ])
        XCTAssertTrue(DropReceiver.canRead(pb))
    }

    func testCanReadReturnsTrueForWebURL() {
        let pb = makePasteboard(items: [
            [.URL: "https://example.com"]
        ])
        XCTAssertTrue(DropReceiver.canRead(pb))
    }

    func testCanReadReturnsTrueForString() {
        let pb = makePasteboard(items: [
            [.string: "hello world"]
        ])
        XCTAssertTrue(DropReceiver.canRead(pb))
    }

    func testCanReadReturnsFalseForEmptyPasteboard() {
        let pb = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pb.clearContents()
        XCTAssertFalse(DropReceiver.canRead(pb))
    }

    func testCanReadReturnsFalseForWhitespaceOnlyString() {
        let pb = makePasteboard(items: [
            [.string: "   \n  "]
        ])
        XCTAssertFalse(DropReceiver.canRead(pb))
    }

    // MARK: - previewDescriptor

    func testPreviewDescriptorSingleFile() {
        let pb = makePasteboard(items: [
            [.fileURL: "file:///Users/test/doc.pdf"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pb)

        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.itemCount, 1)
        XCTAssertEqual(descriptor?.summaryTitle, "doc.pdf")
        XCTAssertEqual(descriptor?.summarySubtitle, "1 file")
    }

    func testPreviewDescriptorWebURL() {
        let pb = makePasteboard(items: [
            [.URL: "https://swift.org/docs"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pb)

        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.summaryTitle, "swift.org")
        XCTAssertEqual(descriptor?.summarySubtitle, "1 URL")
    }

    func testPreviewDescriptorTextClip() {
        let pb = makePasteboard(items: [
            [.string: "Just some text"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pb)

        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.summaryTitle, "Just some text")
        XCTAssertEqual(descriptor?.summarySubtitle, "1 text clip")
    }

    func testPreviewDescriptorStringThatIsURLDetectedAsURL() {
        let pb = makePasteboard(items: [
            [.string: "https://example.com/page"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pb)

        XCTAssertNotNil(descriptor)
        XCTAssertEqual(descriptor?.summarySubtitle, "1 URL")
    }

    func testPreviewDescriptorDeduplicates() {
        let pb = makePasteboard(items: [
            [.fileURL: "file:///tmp/a.txt"],
            [.fileURL: "file:///tmp/a.txt"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pb)

        XCTAssertEqual(descriptor?.itemCount, 1)
    }

    func testPreviewDescriptorReturnsNilForEmpty() {
        let pb = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pb.clearContents()

        XCTAssertNil(DropReceiver.previewDescriptor(from: pb))
    }

    // MARK: - supportedDraggedTypes

    func testSupportedTypes() {
        let types = DropReceiver.supportedDraggedTypes
        XCTAssertTrue(types.contains(.fileURL))
        XCTAssertTrue(types.contains(.URL))
        XCTAssertTrue(types.contains(.string))
    }

    // MARK: - DropReceiverView.dropOperation

    func testDropOperationRejectsUnreadable() {
        let op = DropReceiverView<EmptyView>.dropOperation(
            canRead: false,
            sourceOperationMask: [.copy, .move],
            isSameWindowSource: false
        )
        XCTAssertTrue(op.isEmpty)
    }

    func testDropOperationRejectsSameWindow() {
        let op = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: [.copy, .move],
            isSameWindowSource: true
        )
        XCTAssertTrue(op.isEmpty)
    }

    func testDropOperationPrefersMove() {
        let op = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: [.copy, .move],
            isSameWindowSource: false
        )
        XCTAssertEqual(op, .move)
    }

    func testDropOperationFallsToCopy() {
        let op = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: .copy,
            isSameWindowSource: false
        )
        XCTAssertEqual(op, .copy)
    }

    func testDropOperationEmptyWhenNoSupportedMask() {
        let op = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: .delete,
            isSameWindowSource: false
        )
        XCTAssertTrue(op.isEmpty)
    }

    // MARK: - Helpers

    private func makePasteboard(
        items: [[NSPasteboard.PasteboardType: String]]
    ) -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()

        let pasteboardItems = items.map { values in
            let item = NSPasteboardItem()
            for (type, value) in values {
                item.setString(value, forType: type)
            }
            return item
        }

        XCTAssertTrue(pasteboard.writeObjects(pasteboardItems))
        return pasteboard
    }
}
