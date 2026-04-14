import XCTest
import SwiftUI
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

    func testWithinApplicationSourceMaskAllowsMove() {
        let item = ShelfItem(text: "hello")

        let mask = DragSourceController.sourceOperationMask(for: [item], context: .withinApplication)

        XCTAssertTrue(mask.contains(.move))
    }

    func testInternalMoveConsumesExportedItems() {
        let exportedID = UUID()

        let shouldConsume = DragSourceController.shouldConsumeExportedItems(
            after: .move,
            didLeaveApplication: false,
            exportedItemIDs: [exportedID]
        )

        XCTAssertTrue(shouldConsume)
    }

    func testInternalCopyDoesNotConsumeExportedItems() {
        let exportedID = UUID()

        let shouldConsume = DragSourceController.shouldConsumeExportedItems(
            after: .copy,
            didLeaveApplication: false,
            exportedItemIDs: [exportedID]
        )

        XCTAssertFalse(shouldConsume)
    }

    func testDropReceiverRejectsSameShelfDrop() {
        let operation = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: [.copy, .move],
            isSameWindowSource: true
        )

        XCTAssertTrue(operation.isEmpty)
    }

    func testDropReceiverPrefersMoveForCrossShelfDrop() {
        let operation = DropReceiverView<EmptyView>.dropOperation(
            canRead: true,
            sourceOperationMask: [.copy, .move],
            isSameWindowSource: false
        )

        XCTAssertEqual(operation, .move)
    }

    // MARK: - Append auto-selection

    func testAppendSelectsFirstItemWhenNothingSelected() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))

        let items = [
            ShelfItem(text: "first"),
            ShelfItem(text: "second")
        ]
        viewModel.append(items: items)

        XCTAssertEqual(viewModel.selectedItemIDs, [items[0].id])
    }

    func testAppendDoesNotChangeExistingSelection() {
        let existing = ShelfItem(text: "existing")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [existing])
        )
        viewModel.select(existing)

        let newItem = ShelfItem(text: "new")
        viewModel.append(items: [newItem])

        XCTAssertEqual(viewModel.selectedItemIDs, [existing.id])
    }

    func testAppendEmptyArrayIsNoOp() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        viewModel.append(items: [])

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(viewModel.selectedItemIDs.isEmpty)
    }

    // MARK: - draggedItems

    func testDraggedItemsReturnsSelectionWhenAnchorIsSelected() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let c = ShelfItem(text: "c")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a, b, c])
        )
        viewModel.setSelection(ids: [a.id, b.id])

        let dragged = viewModel.draggedItems(anchorID: a.id)

        XCTAssertEqual(Set(dragged.map(\.id)), [a.id, b.id])
    }

    func testDraggedItemsReturnsOnlyAnchorWhenNotInSelection() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a, b])
        )
        viewModel.select(a)

        let dragged = viewModel.draggedItems(anchorID: b.id)

        XCTAssertEqual(dragged.map(\.id), [b.id])
    }

    func testDraggedItemsReturnsAnchorWhenSelectionEmpty() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a])
        )

        let dragged = viewModel.draggedItems(anchorID: a.id)

        XCTAssertEqual(dragged.map(\.id), [a.id])
    }

    // MARK: - toggleSelectAll

    func testToggleSelectAllSelectsWhenNotFull() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a, b])
        )

        viewModel.toggleSelectAll()

        XCTAssertEqual(viewModel.selectedItemIDs, [a.id, b.id])
    }

    func testToggleSelectAllClearsWhenFull() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a, b])
        )
        viewModel.selectAll()

        viewModel.toggleSelectAll()

        XCTAssertTrue(viewModel.selectedItemIDs.isEmpty)
    }

    // MARK: - setSelection filters invalid IDs

    func testSetSelectionFiltersInvalidIDs() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a])
        )

        viewModel.setSelection(ids: [a.id, UUID()])

        XCTAssertEqual(viewModel.selectedItemIDs, [a.id])
    }

    // MARK: - isSelected

    func testIsSelected() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [a, b])
        )
        viewModel.select(a)

        XCTAssertTrue(viewModel.isSelected(a))
        XCTAssertFalse(viewModel.isSelected(b))
    }

    // MARK: - itemCountDescription

    func testItemCountDescriptionSingular() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [ShelfItem(text: "one")])
        )
        XCTAssertEqual(viewModel.itemCountDescription, "1 item")
    }

    func testItemCountDescriptionPlural() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [ShelfItem(text: "a"), ShelfItem(text: "b")])
        )
        XCTAssertEqual(viewModel.itemCountDescription, "2 items")
    }

    func testItemCountDescriptionEmpty() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        XCTAssertEqual(viewModel.itemCountDescription, "0 items")
    }

    // MARK: - showSelectionControl

    func testShowSelectionControlFalseInPreviewMode() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [ShelfItem(text: "a"), ShelfItem(text: "b")]),
            presentationMode: .preview(.placeholder)
        )
        XCTAssertFalse(viewModel.showSelectionControl)
    }

    func testShowSelectionControlFalseForSingleItem() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [ShelfItem(text: "a")])
        )
        XCTAssertFalse(viewModel.showSelectionControl)
    }

    func testShowSelectionControlTrueForMultipleItems() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S", items: [ShelfItem(text: "a"), ShelfItem(text: "b")])
        )
        XCTAssertTrue(viewModel.showSelectionControl)
    }

    // MARK: - hasSelection / hasFullSelection

    func testHasSelectionWhenEmpty() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [ShelfItem(text: "a")]))
        XCTAssertFalse(viewModel.hasSelection)
    }

    func testHasSelectionWhenSelected() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a]))
        viewModel.select(a)
        XCTAssertTrue(viewModel.hasSelection)
    }

    func testHasFullSelectionFalseForPartial() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a, b]))
        viewModel.select(a)
        XCTAssertFalse(viewModel.hasFullSelection)
    }

    func testHasFullSelectionTrueWhenAllSelected() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a]))
        viewModel.selectAll()
        XCTAssertTrue(viewModel.hasFullSelection)
    }

    func testHasFullSelectionFalseWhenEmpty() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        XCTAssertFalse(viewModel.hasFullSelection)
    }

    // MARK: - title / isPreview / previewDescriptor

    func testTitle() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "My Shelf"))
        XCTAssertEqual(viewModel.title, "My Shelf")
    }

    func testIsPreviewInExpandedMode() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        XCTAssertFalse(viewModel.isPreview)
    }

    func testIsPreviewInPreviewMode() {
        let viewModel = ShelfViewModel(
            shelf: Shelf(name: "S"),
            presentationMode: .preview(.placeholder)
        )
        XCTAssertTrue(viewModel.isPreview)
    }

    func testPreviewDescriptorNilInExpanded() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        XCTAssertNil(viewModel.previewDescriptor)
    }

    // MARK: - setPresentationMode

    func testSetPresentationMode() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        XCTAssertFalse(viewModel.isPreview)

        viewModel.setPresentationMode(.preview(.placeholder))
        XCTAssertTrue(viewModel.isPreview)

        viewModel.setPresentationMode(.expanded)
        XCTAssertFalse(viewModel.isPreview)
    }

    // MARK: - requestClose

    func testRequestCloseInvokesCallback() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        var called = false
        viewModel.closeShelf = { called = true }

        viewModel.requestClose()

        XCTAssertTrue(called)
    }

    func testRequestCloseDoesNothingWithoutCallback() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        viewModel.requestClose() // should not crash
    }

    // MARK: - removeItems edge cases

    func testRemoveEmptySetIsNoOp() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a]))
        viewModel.removeItems(ids: [])
        XCTAssertEqual(viewModel.items.count, 1)
    }

    func testRemoveNonexistentIDIsNoOp() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a]))
        viewModel.removeItems(ids: [UUID()])
        XCTAssertEqual(viewModel.items.count, 1)
    }

    func testCloseNotTriggeredWhenShelfAlreadyEmpty() {
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S"))
        var closeCount = 0
        viewModel.closeShelf = { closeCount += 1 }

        viewModel.removeItems(ids: [UUID()])
        XCTAssertEqual(closeCount, 0)
    }

    // MARK: - consumeExportedItemsAndCloseIfEmpty filters to valid IDs

    func testConsumeExportedItemsFiltersInvalidIDs() {
        let a = ShelfItem(text: "a")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a]))

        viewModel.consumeExportedItemsAndCloseIfEmpty(ids: [UUID()])

        XCTAssertEqual(viewModel.items.count, 1)
    }

    // MARK: - items(for:)

    func testItemsForIDs() {
        let a = ShelfItem(text: "a")
        let b = ShelfItem(text: "b")
        let c = ShelfItem(text: "c")
        let viewModel = ShelfViewModel(shelf: Shelf(name: "S", items: [a, b, c]))

        let result = viewModel.items(for: [a.id, c.id])

        XCTAssertEqual(Set(result.map(\.id)), [a.id, c.id])
    }
}
