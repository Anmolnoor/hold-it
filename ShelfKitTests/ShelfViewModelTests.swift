import XCTest
@testable import ShelfKit

@MainActor
final class ShelfViewModelTests: XCTestCase {
    func testSelectAllSelectsEveryItem() {
        let items = [
            ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/one.txt"), isDirectory: false),
            ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/two.txt"), isDirectory: false),
            ShelfItem(text: "hello")
        ]
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "Shelf", items: items)
        )

        viewModel.selectAll()

        XCTAssertEqual(viewModel.selectedItemIDs, Set(items.map(\.id)))
    }

    func testConsumeExportedItemsRemovesEveryExportedType() {
        let fileItem = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/file.txt"), isDirectory: false)
        let folderItem = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/folder"), isDirectory: true)
        let textItem = ShelfItem(text: "hello")
        let urlItem = ShelfItem(url: URL(string: "https://example.com")!)

        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "Shelf", items: [fileItem, folderItem, textItem, urlItem])
        )

        viewModel.consumeExportedItemsAndCloseIfEmpty(ids: [fileItem.id, textItem.id, urlItem.id])

        XCTAssertEqual(viewModel.items.map(\.id), [folderItem.id])
    }

    func testRemoveItemsClearsSelectionForRemovedRows() {
        let first = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/one.txt"), isDirectory: false)
        let second = ShelfItem(fileURL: URL(fileURLWithPath: "/tmp/two.txt"), isDirectory: false)
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "Shelf", items: [first, second])
        )

        viewModel.selectAll()
        viewModel.removeItems(ids: [first.id])

        XCTAssertEqual(viewModel.items.map(\.id), [second.id])
        XCTAssertEqual(viewModel.selectedItemIDs, [second.id])
    }

    func testClosingTriggeredWhenItemCountTransitionsToZero() {
        let textItem = ShelfItem(text: "hello")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "Shelf", items: [textItem])
        )

        var closeInvocations = 0
        viewModel.closeShelf = {
            closeInvocations += 1
        }

        viewModel.consumeExportedItemsAndCloseIfEmpty(ids: [textItem.id])

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(closeInvocations, 1)
    }
}
