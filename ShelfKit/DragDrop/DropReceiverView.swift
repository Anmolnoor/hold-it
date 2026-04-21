import AppKit
import SwiftUI

@MainActor
final class DropReceiverView<Content: View>: NSView {
    private let hostingView: NSHostingView<Content>
    private let onItemsDropped: ([ShelfItem]) -> Void
    private let onDropTargetActiveChanged: (Bool) -> Void
    private let showsBorderHighlight: Bool

    init(
        rootView: Content,
        onItemsDropped: @escaping ([ShelfItem]) -> Void,
        onDropTargetActiveChanged: @escaping (Bool) -> Void = { _ in },
        showsBorderHighlight: Bool = true
    ) {
        self.hostingView = NSHostingView(rootView: rootView)
        self.onItemsDropped = onItemsDropped
        self.onDropTargetActiveChanged = onDropTargetActiveChanged
        self.showsBorderHighlight = showsBorderHighlight

        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 20
        layer?.borderWidth = 0
        layer?.borderColor = NSColor.controlAccentColor.cgColor

        registerForDraggedTypes(DropReceiver.supportedDraggedTypes)
        configureHostingView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let operation = Self.dropOperation(
            canRead: DropReceiver.canRead(sender.draggingPasteboard),
            sourceOperationMask: sender.draggingSourceOperationMask,
            isSameWindowSource: isDragFromSameWindow(sender)
        )
        updateHighlight(isHighlighted: operation.isEmpty == false)
        return operation
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        updateHighlight(isHighlighted: false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        Self.dropOperation(
            canRead: DropReceiver.canRead(sender.draggingPasteboard),
            sourceOperationMask: sender.draggingSourceOperationMask,
            isSameWindowSource: isDragFromSameWindow(sender)
        ).isEmpty == false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let items = DropReceiver.items(from: sender.draggingPasteboard)
        updateHighlight(isHighlighted: false)

        guard items.isEmpty == false else {
            return false
        }

        onItemsDropped(items)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        updateHighlight(isHighlighted: false)
    }

    private func configureHostingView() {
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateHighlight(isHighlighted: Bool) {
        layer?.borderWidth = showsBorderHighlight && isHighlighted ? 3 : 0
        onDropTargetActiveChanged(isHighlighted)
    }

    static func dropOperation(
        canRead: Bool,
        sourceOperationMask: NSDragOperation,
        isSameWindowSource: Bool
    ) -> NSDragOperation {
        guard canRead else {
            return []
        }

        guard isSameWindowSource == false else {
            return []
        }

        if sourceOperationMask.contains(.move) {
            return .move
        }

        if sourceOperationMask.contains(.copy) {
            return .copy
        }

        return []
    }

    private func isDragFromSameWindow(_ sender: NSDraggingInfo) -> Bool {
        guard let sourceView = sender.draggingSource as? NSView else {
            return false
        }

        return sourceView.window === window
    }
}
