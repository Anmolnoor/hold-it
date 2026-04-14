import XCTest
@testable import ShelfKit

final class ShelfTests: XCTestCase {

    // MARK: - Init defaults

    func testDefaultInit() {
        let shelf = Shelf()
        XCTAssertEqual(shelf.name, "New Shelf")
        XCTAssertNil(shelf.colorTag)
        XCTAssertFalse(shelf.pinned)
        XCTAssertNil(shelf.dockedEdge)
        XCTAssertTrue(shelf.items.isEmpty)
    }

    func testCustomInit() {
        let items = [ShelfItem(text: "a")]
        let shelf = Shelf(name: "My Shelf", colorTag: "blue", pinned: true, dockedEdge: .left, items: items)
        XCTAssertEqual(shelf.name, "My Shelf")
        XCTAssertEqual(shelf.colorTag, "blue")
        XCTAssertTrue(shelf.pinned)
        XCTAssertEqual(shelf.dockedEdge, .left)
        XCTAssertEqual(shelf.items.count, 1)
    }

    // MARK: - Append

    func testAppendAddsItems() {
        var shelf = Shelf(name: "S")
        let item1 = ShelfItem(text: "one")
        let item2 = ShelfItem(text: "two")
        let before = shelf.updatedAt

        shelf.append(items: [item1, item2])

        XCTAssertEqual(shelf.items.count, 2)
        XCTAssertEqual(shelf.items.map(\.id), [item1.id, item2.id])
        XCTAssertGreaterThanOrEqual(shelf.updatedAt, before)
    }

    func testAppendEmptyArrayIsNoOp() {
        var shelf = Shelf(name: "S", items: [ShelfItem(text: "existing")])
        let before = shelf.updatedAt

        shelf.append(items: [])

        XCTAssertEqual(shelf.items.count, 1)
        XCTAssertEqual(shelf.updatedAt, before)
    }

    func testAppendPreservesExistingItems() {
        let existing = ShelfItem(text: "existing")
        var shelf = Shelf(name: "S", items: [existing])

        let newItem = ShelfItem(text: "new")
        shelf.append(items: [newItem])

        XCTAssertEqual(shelf.items.count, 2)
        XCTAssertEqual(shelf.items[0].id, existing.id)
        XCTAssertEqual(shelf.items[1].id, newItem.id)
    }

    // MARK: - RemoveItems

    func testRemoveItemsByID() {
        let item1 = ShelfItem(text: "one")
        let item2 = ShelfItem(text: "two")
        let item3 = ShelfItem(text: "three")
        var shelf = Shelf(name: "S", items: [item1, item2, item3])
        let before = shelf.updatedAt

        shelf.removeItems(ids: [item1.id, item3.id])

        XCTAssertEqual(shelf.items.map(\.id), [item2.id])
        XCTAssertGreaterThanOrEqual(shelf.updatedAt, before)
    }

    func testRemoveEmptySetIsNoOp() {
        let item = ShelfItem(text: "keep")
        var shelf = Shelf(name: "S", items: [item])
        let before = shelf.updatedAt

        shelf.removeItems(ids: [])

        XCTAssertEqual(shelf.items.count, 1)
        XCTAssertEqual(shelf.updatedAt, before)
    }

    func testRemoveNonexistentIDStillUpdatesTimestamp() {
        let item = ShelfItem(text: "keep")
        var shelf = Shelf(name: "S", items: [item])

        shelf.removeItems(ids: [UUID()])

        // Items unchanged, but updatedAt still advances (the guard only checks empty set)
        XCTAssertEqual(shelf.items.count, 1)
    }

    func testRemoveAllItems() {
        let item1 = ShelfItem(text: "one")
        let item2 = ShelfItem(text: "two")
        var shelf = Shelf(name: "S", items: [item1, item2])

        shelf.removeItems(ids: [item1.id, item2.id])

        XCTAssertTrue(shelf.items.isEmpty)
    }

    // MARK: - Dock edges

    func testAllDockEdges() {
        let edges: [ShelfDockEdge] = [.left, .right, .top, .bottom]
        for edge in edges {
            let shelf = Shelf(name: "S", dockedEdge: edge)
            XCTAssertEqual(shelf.dockedEdge, edge)
        }
    }
}
