import AppKit
import XCTest
@testable import ShelfKit

final class ShelfNotchSupportTests: XCTestCase {
    func testGeometryReturnsNilWithoutTopInset() {
        let geometry = ShelfNotchSupport.geometry(
            screenFrame: NSRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaInsets: .init(top: 0, left: 0, bottom: 0, right: 0)
        )

        XCTAssertNil(geometry)
    }

    func testGeometryReturnsValueWithTopInset() {
        let geometry = ShelfNotchSupport.geometry(
            screenFrame: NSRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaInsets: .init(top: 32, left: 0, bottom: 0, right: 0)
        )

        XCTAssertNotNil(geometry)
        XCTAssertEqual(geometry?.safeAreaTopY, 950)
    }

    func testNotchFrameCentersUnderTopInset() {
        let geometry = ShelfNotchGeometry(
            screenFrame: NSRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaInsets: .init(top: 32, left: 0, bottom: 0, right: 0)
        )

        let frame = ShelfPositioner.notchFrame(
            geometry: geometry,
            size: CGSize(width: 248, height: 66)
        )

        XCTAssertEqual(frame.origin.x, 632)
        XCTAssertEqual(frame.origin.y, 878)
        XCTAssertEqual(frame.size, CGSize(width: 248, height: 66))
    }
}
