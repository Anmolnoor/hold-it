import AppKit
import SwiftUI

@MainActor
final class DropReceiverView<Content: View>: NSView {
    private let hostingView: NSHostingView<Content>
    private let onItemsDropped: ([ShelfItem]) -> Void

    init(rootView: Content, onItemsDropped: @escaping ([ShelfItem]) -> Void) {
        self.hostingView = NSHostingView(rootView: rootView)
        self.onItemsDropped = onItemsDropped

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
        guard DropReceiver.canRead(sender.draggingPasteboard) else {
            updateHighlight(isHighlighted: false)
            return []
        }

        updateHighlight(isHighlighted: true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        updateHighlight(isHighlighted: false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        DropReceiver.canRead(sender.draggingPasteboard)
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
        layer?.borderWidth = isHighlighted ? 3 : 0
    }
}
