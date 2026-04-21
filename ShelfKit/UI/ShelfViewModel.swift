import AppKit
import Combine

@MainActor
final class ShelfViewModel: ObservableObject {
    @Published private(set) var shelf: Shelf
    @Published private(set) var presentationMode: ShelfPresentationMode
    @Published private(set) var selectedItemIDs: Set<ShelfItem.ID> = []
    @Published private(set) var isDropTargetActive = false

    var closeShelf: (() -> Void)?

    init(
        shelf: Shelf,
        presentationMode: ShelfPresentationMode = .expanded
    ) {
        self.shelf = shelf
        self.presentationMode = presentationMode
    }

    var title: String {
        shelf.name
    }

    var items: [ShelfItem] {
        shelf.items
    }

    var hotkeyDescription: String {
        GlobalHotkeyController.Shortcut.newShelf.displayName
    }

    var isPreview: Bool {
        presentationMode.isPreview
    }

    var isNotchPresentation: Bool {
        presentationMode.isNotchPresentation
    }

    var previewDescriptor: DragPreviewDescriptor? {
        presentationMode.previewDescriptor
    }

    var itemCountDescription: String {
        let count = shelf.items.count
        return count == 1 ? "1 item" : "\(count) items"
    }

    var hasSelection: Bool {
        selectedItemIDs.isEmpty == false
    }

    var hasFullSelection: Bool {
        items.isEmpty == false && selectedItemIDs.count == items.count
    }

    var showSelectionControl: Bool {
        presentationMode.isPreview == false && items.count > 1
    }

    var notchLeadingSymbolName: String {
        let itemTypes = Set(items.map(\.type))

        if items.isEmpty {
            return "tray"
        }

        if itemTypes.allSatisfy({ $0 == .file || $0 == .folder }) {
            return "doc.fill"
        }

        if itemTypes.count == 1, itemTypes.contains(.text) {
            return "text.alignleft"
        }

        if itemTypes.count == 1, itemTypes.contains(.url) {
            return "link"
        }

        return "square.stack.3d.up.fill"
    }

    var notchCountText: String {
        "\(items.count)"
    }

    var notchTitle: String {
        items.isEmpty ? "Drop files here" : title
    }

    var notchSubtitle: String {
        items.isEmpty ? "Collect under the notch" : itemCountDescription
    }

    func append(items newItems: [ShelfItem]) {
        guard newItems.isEmpty == false else {
            return
        }

        var updatedShelf = shelf
        updatedShelf.append(items: newItems)
        shelf = updatedShelf

        if selectedItemIDs.isEmpty {
            selectedItemIDs = Set(newItems.prefix(1).map(\.id))
        }
    }

    func select(_ item: ShelfItem) {
        selectedItemIDs = [item.id]
    }

    func isSelected(_ item: ShelfItem) -> Bool {
        selectedItemIDs.contains(item.id)
    }

    func setSelection(ids: Set<ShelfItem.ID>) {
        let validIDs = Set(items.map(\.id))
        selectedItemIDs = ids.intersection(validIDs)
    }

    func clearSelection() {
        selectedItemIDs.removeAll()
    }

    func selectAll() {
        selectedItemIDs = Set(items.map(\.id))
    }

    func toggleSelectAll() {
        hasFullSelection ? clearSelection() : selectAll()
    }

    func removeItems(ids: Set<ShelfItem.ID>) {
        guard ids.isEmpty == false else {
            return
        }

        let previousCount = shelf.items.count
        var updatedShelf = shelf
        updatedShelf.removeItems(ids: ids)
        guard updatedShelf.items.count != previousCount else {
            return
        }

        shelf = updatedShelf
        selectedItemIDs.subtract(ids)
        closeShelfIfEmptied(previousCount: previousCount)
    }

    func consumeExportedItemsAndCloseIfEmpty(ids: Set<ShelfItem.ID>) {
        let removableIDs = Set(items.map(\.id)).intersection(ids)
        removeItems(ids: removableIDs)
    }

    func setPresentationMode(_ mode: ShelfPresentationMode) {
        presentationMode = mode
    }

    func setDropTargetActive(_ isActive: Bool) {
        isDropTargetActive = isActive
    }

    func items(for ids: Set<ShelfItem.ID>) -> [ShelfItem] {
        items.filter { ids.contains($0.id) }
    }

    func draggedItems(anchorID: ShelfItem.ID) -> [ShelfItem] {
        if selectedItemIDs.contains(anchorID), selectedItemIDs.isEmpty == false {
            return items(for: selectedItemIDs)
        }

        return items.filter { $0.id == anchorID }
    }

    func requestClose() {
        closeShelf?()
    }

    private func closeShelfIfEmptied(previousCount: Int) {
        guard previousCount > 0, shelf.items.isEmpty else {
            return
        }

        closeShelf?()
    }
}
