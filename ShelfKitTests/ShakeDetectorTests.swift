import AppKit
import CoreGraphics
import XCTest
@testable import ShelfKit

final class ShakeDetectorTests: XCTestCase {
    func testDefaultDetectorTriggersForShortWiggle() {
        var detector = ShakeDetector()

        XCTAssertFalse(detector.ingest(point: CGPoint(x: 0, y: 0), timestamp: 0.0))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 45, y: 3), timestamp: 0.12))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: -35, y: 7), timestamp: 0.24))
        XCTAssertTrue(detector.ingest(point: CGPoint(x: 60, y: 10), timestamp: 0.36))
    }

    func testDefaultDetectorTriggersForVerticalWiggle() {
        var detector = ShakeDetector()

        XCTAssertFalse(detector.ingest(point: CGPoint(x: 0, y: 0), timestamp: 0.0))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 4, y: 45), timestamp: 0.12))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 7, y: -35), timestamp: 0.24))
        XCTAssertTrue(detector.ingest(point: CGPoint(x: 10, y: 60), timestamp: 0.36))
    }

    func testDetectorTriggersOnlyOncePerDragGesture() {
        var detector = ShakeDetector(
            windowDuration: 1.0,
            minimumHorizontalTravel: 90,
            minimumSegmentDelta: 10,
            minimumReversals: 3,
            maximumVerticalDrift: 120
        )

        XCTAssertFalse(detector.ingest(point: CGPoint(x: 0, y: 0), timestamp: 0.0))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 40, y: 3), timestamp: 0.1))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: -30, y: 6), timestamp: 0.2))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 55, y: 9), timestamp: 0.3))
        XCTAssertTrue(detector.ingest(point: CGPoint(x: -45, y: 12), timestamp: 0.4))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 70, y: 10), timestamp: 0.5))
    }

    func testResetAllowsSecondTrigger() {
        var detector = ShakeDetector(
            windowDuration: 1.0,
            minimumHorizontalTravel: 90,
            minimumSegmentDelta: 10,
            minimumReversals: 3,
            maximumVerticalDrift: 120
        )

        _ = detector.ingest(point: CGPoint(x: 0, y: 0), timestamp: 0.0)
        _ = detector.ingest(point: CGPoint(x: 40, y: 2), timestamp: 0.1)
        _ = detector.ingest(point: CGPoint(x: -30, y: 5), timestamp: 0.2)
        _ = detector.ingest(point: CGPoint(x: 55, y: 7), timestamp: 0.3)
        XCTAssertTrue(detector.ingest(point: CGPoint(x: -45, y: 10), timestamp: 0.4))

        detector.reset()

        XCTAssertFalse(detector.ingest(point: CGPoint(x: 0, y: 0), timestamp: 1.0))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 45, y: 3), timestamp: 1.1))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: -35, y: 6), timestamp: 1.2))
        XCTAssertFalse(detector.ingest(point: CGPoint(x: 60, y: 8), timestamp: 1.3))
        XCTAssertTrue(detector.ingest(point: CGPoint(x: -50, y: 11), timestamp: 1.4))
    }

    func testPreviewDescriptorUsesRawFileURLStrings() {
        let pasteboard = makePasteboard(items: [
            [.fileURL: "file:///Users/tester/Desktop/Quarterly%20Notes.pdf"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pasteboard)

        XCTAssertEqual(descriptor?.summaryTitle, "Quarterly Notes.pdf")
        XCTAssertEqual(descriptor?.summarySubtitle, "1 file")
        XCTAssertEqual(descriptor?.primaryIconNames, ["doc"])
    }

    func testPreviewDescriptorBuildsMixedDragSummaryWithoutResolvingObjects() {
        let pasteboard = makePasteboard(items: [
            [.fileURL: "file:///Users/tester/Desktop/Notes.txt"],
            [.URL: "https://example.com/docs"],
            [.string: "Draft copy to revisit"]
        ])

        let descriptor = DropReceiver.previewDescriptor(from: pasteboard)

        XCTAssertEqual(descriptor?.summaryTitle, "3 items")
        XCTAssertEqual(descriptor?.summarySubtitle, "1 file • 1 text clip • 1 URL")
        XCTAssertEqual(descriptor?.primaryIconNames, ["doc", "link", "text.alignleft"])
    }

    func testDragPreviewFramePlacesCursorInsidePreview() {
        let cursorLocation = CGPoint(x: 640, y: 420)
        let frame = ShelfPositioner.dragPreviewFrame(
            under: cursorLocation,
            size: CGSize(width: 280, height: 124)
        )

        XCTAssertTrue(frame.contains(cursorLocation))
    }

    func testTopLeftFrameAnchorsNearVisibleFrameTopLeft() {
        let frame = ShelfPositioner.topLeftFrame(
            near: CGPoint(x: 640, y: 420),
            size: CGSize(width: 280, height: 124)
        )

        XCTAssertEqual(frame.origin.x, 20, accuracy: 0.5)
        XCTAssertGreaterThan(frame.origin.y, 0)
    }

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
