import AppKit
import SwiftUI

@MainActor
final class ShelfWindowController: NSWindowController, NSWindowDelegate {
    static let landedShelfSize = CGSize(width: 240, height: 240)

    let shelfID: UUID
    var onClose: ((UUID) -> Void)?
    var onItemsDropped: ((UUID) -> Void)?

    private let viewModel: ShelfViewModel
    private var hasAcceptedDrop = false

    init(
        shelf: Shelf,
        presentationMode: ShelfPresentationMode = .expanded
    ) {
        self.shelfID = shelf.id
        self.viewModel = ShelfViewModel(
            shelf: shelf,
            presentationMode: presentationMode
        )

        let initialSize = presentationMode.isPreview
            ? CGSize(width: 280, height: 124)
            : Self.landedShelfSize
        let panel = ShelfPanel(
            frame: NSRect(origin: .zero, size: initialSize),
            presentationMode: presentationMode
        )
        super.init(window: panel)

        panel.delegate = self
        panel.title = shelf.name

        viewModel.closeShelf = { [weak panel] in
            panel?.close()
        }

        let rootView = ShelfRootView(viewModel: viewModel)
        let dropView = DropReceiverView(rootView: rootView) { [weak self] items in
            self?.handleDroppedItems(items)
        }
        panel.contentView = dropView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(frame: NSRect) {
        guard let window else {
            return
        }

        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
    }

    func cancelPreviewIfEmpty() {
        guard
            viewModel.isPreview,
            viewModel.items.isEmpty,
            hasAcceptedDrop == false
        else {
            return
        }

        close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?(shelfID)
    }

    private func handleDroppedItems(_ items: [ShelfItem]) {
        guard items.isEmpty == false else {
            return
        }

        hasAcceptedDrop = true
        onItemsDropped?(shelfID)
        let shouldPromotePreview = viewModel.isPreview

        // Allow AppKit to finish the drop before converting and moving the preview shelf.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else {
                return
            }

            self.viewModel.append(items: items)

            if shouldPromotePreview {
                self.promoteDroppedPreviewShelf()
            }

            self.hasAcceptedDrop = false
        }
    }

    private func promoteDroppedPreviewShelf() {
        guard let window else {
            return
        }

        viewModel.setPresentationMode(.expanded)
        (window as? ShelfPanel)?.applyPresentationMode(.expanded)
        let targetFrame = ShelfPositioner.topLeftFrame(
            near: CGPoint(x: window.frame.midX, y: window.frame.midY),
            size: Self.landedShelfSize
        )

        window.setFrame(targetFrame, display: true, animate: false)
        window.orderFrontRegardless()
    }
}
