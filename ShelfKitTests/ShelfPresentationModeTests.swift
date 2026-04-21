import XCTest
@testable import ShelfKit

final class ShelfPresentationModeTests: XCTestCase {

    func testExpandedIsNotPreview() {
        let mode = ShelfPresentationMode.expanded
        XCTAssertFalse(mode.isPreview)
    }

    func testExpandedPreviewDescriptorIsNil() {
        let mode = ShelfPresentationMode.expanded
        XCTAssertNil(mode.previewDescriptor)
    }

    func testNotchExpandedFlags() {
        let mode = ShelfPresentationMode.notchExpanded
        XCTAssertFalse(mode.isPreview)
        XCTAssertTrue(mode.isNotchPresentation)
        XCTAssertNil(mode.previewDescriptor)
    }

    func testPreviewIsPreview() {
        let descriptor = DragPreviewDescriptor.placeholder
        let mode = ShelfPresentationMode.preview(descriptor)
        XCTAssertTrue(mode.isPreview)
    }

    func testPreviewReturnsDescriptor() {
        let descriptor = DragPreviewDescriptor(
            itemCount: 2,
            primaryIconNames: ["doc", "link"],
            summaryTitle: "2 items",
            summarySubtitle: "1 file • 1 URL"
        )
        let mode = ShelfPresentationMode.preview(descriptor)

        let returned = mode.previewDescriptor
        XCTAssertEqual(returned, descriptor)
        XCTAssertEqual(returned?.itemCount, 2)
        XCTAssertEqual(returned?.summaryTitle, "2 items")
    }

    func testNotchPreviewReturnsDescriptor() {
        let descriptor = DragPreviewDescriptor.placeholder
        let mode = ShelfPresentationMode.notchPreview(descriptor)

        XCTAssertTrue(mode.isPreview)
        XCTAssertTrue(mode.isNotchPresentation)
        XCTAssertEqual(mode.previewDescriptor, descriptor)
    }

    func testEquatable() {
        let a = ShelfPresentationMode.expanded
        let b = ShelfPresentationMode.expanded
        XCTAssertEqual(a, b)

        let desc = DragPreviewDescriptor.placeholder
        let c = ShelfPresentationMode.preview(desc)
        let d = ShelfPresentationMode.preview(desc)
        XCTAssertEqual(c, d)

        XCTAssertNotEqual(a, c)
        XCTAssertNotEqual(.notchExpanded, c)
    }
}
