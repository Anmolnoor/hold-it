import AppKit

@MainActor
final class ShelfCoordinator {
    private var windowControllers: [UUID: ShelfWindowController] = [:]
    private var activePreviewShelfID: UUID?
    private var creationIndex = 0

    init(preferencesStore _: PreferencesStore) {}

    @discardableResult
    func createShelf() -> ShelfWindowController {
        createShelf(
            presentationMode: .expanded,
            frame: ShelfPositioner.initialFrame(
                for: ShelfWindowController.landedShelfSize,
                index: creationIndex
            )
        )
    }

    @discardableResult
    func createPreviewShelf(
        descriptor: DragPreviewDescriptor = .placeholder,
        near cursorLocation: CGPoint
    ) -> ShelfWindowController? {
        guard activePreviewShelfID == nil else {
            return nil
        }

        let previewFrame = ShelfPositioner.dragPreviewFrame(
            under: cursorLocation,
            size: CGSize(width: 280, height: 124)
        )
        let controller = createShelf(
            presentationMode: .preview(descriptor),
            frame: previewFrame
        )

        activePreviewShelfID = controller.shelfID
        return controller
    }

    func handleGlobalDragEnded() {
        guard
            let previewShelfID = activePreviewShelfID,
            let controller = windowControllers[previewShelfID]
        else {
            return
        }

        activePreviewShelfID = nil

        // Closing the preview panel inline can race the system drag teardown on macOS.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            controller.cancelPreviewIfEmpty()
        }
    }

    @discardableResult
    private func createShelf(
        presentationMode: ShelfPresentationMode,
        frame: NSRect
    ) -> ShelfWindowController {
        let shelfName = windowControllers.isEmpty ? "Shelf" : "Shelf \(windowControllers.count + 1)"
        let shelf = Shelf(name: shelfName)
        let controller = ShelfWindowController(
            shelf: shelf,
            presentationMode: presentationMode
        )

        controller.onClose = { [weak self] shelfID in
            self?.windowControllers.removeValue(forKey: shelfID)
            if self?.activePreviewShelfID == shelfID {
                self?.activePreviewShelfID = nil
            }
        }

        controller.onItemsDropped = { [weak self] shelfID in
            guard self?.activePreviewShelfID == shelfID else {
                return
            }

            self?.activePreviewShelfID = nil
        }

        windowControllers[shelf.id] = controller
        creationIndex += 1
        controller.show(frame: frame)

        return controller
    }
}
