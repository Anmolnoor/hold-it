import AppKit

struct ShelfExportPayload {
    let items: [ShelfItem]
    let itemIDs: Set<ShelfItem.ID>
    let pasteboardWriters: [NSPasteboardWriting]
}

enum DragSourceController {
    static func wholeShelfExportPayload(for items: [ShelfItem]) -> ShelfExportPayload? {
        let exportedEntries = items.compactMap { item -> (ShelfItem, NSPasteboardWriting)? in
            guard let writer = pasteboardWriter(for: item) else {
                return nil
            }

            return (item, writer)
        }

        let writers = exportedEntries.map(\.1)
        guard writers.isEmpty == false else {
            return nil
        }

        let exportedItems = exportedEntries.map(\.0)
        return ShelfExportPayload(
            items: exportedItems,
            itemIDs: Set(exportedItems.map(\.id)),
            pasteboardWriters: writers
        )
    }

    static func pasteboardWriter(for item: ShelfItem) -> NSPasteboardWriting? {
        switch item.type {
        case .file, .folder:
            if let url = item.originalURL ?? item.localStoredURL {
                return url as NSURL
            }

            return item.displayName as NSString

        case .text:
            return (item.textValue ?? item.displayName) as NSString

        case .url:
            if let url = item.originalURL {
                return url as NSURL
            }

            return item.displayName as NSString
        }
    }

    static func sourceOperationMask(for items: [ShelfItem], context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .withinApplication:
            return items.isEmpty ? [] : [.copy, .move]

        case .outsideApplication:
            return items.contains(where: \.isFileSystemItem) ? [.copy, .move] : .copy

        @unknown default:
            return items.contains(where: \.isFileSystemItem) ? [.copy, .move] : .copy
        }
    }

    static func shouldConsumeExportedItems(
        after operation: NSDragOperation,
        didLeaveApplication: Bool,
        exportedItemIDs: Set<ShelfItem.ID>
    ) -> Bool {
        guard exportedItemIDs.isEmpty == false else {
            return false
        }

        if operation.contains(.move) {
            return true
        }

        return didLeaveApplication && operation.isEmpty == false
    }
}
