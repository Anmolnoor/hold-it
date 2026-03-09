import AppKit
import SwiftUI

struct ShelfRootView: View {
    @ObservedObject var viewModel: ShelfViewModel

    var body: some View {
        Group {
            if viewModel.isPreview {
                previewStateContainer
            } else {
                landedState
            }
        }
    }

    private var previewStateContainer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .underPageBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            previewState
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .frame(minWidth: 250, minHeight: 112)
    }

    private var landedState: some View {
        ZStack {
            Color.black.opacity(0.001)

            landedBackgroundPanel

            landedStackIcon
                .frame(width: 108, height: 132)
                .overlay {
                    ShelfStackDragSourceView(items: viewModel.items) { exportedIDs in
                        viewModel.consumeExportedItemsAndCloseIfEmpty(ids: exportedIDs)
                    }
                }
        }
        .frame(
            width: ShelfWindowController.landedShelfSize.width,
            height: ShelfWindowController.landedShelfSize.height
        )
    }

    private var landedBackgroundPanel: some View {
        RoundedRectangle(cornerRadius: 40, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 212, height: 212)
            .overlay(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 18, y: 8)
    }

    private var landedStackIcon: some View {
        ZStack {
            stackLayer(fillOpacity: 0.22)
                .offset(x: -15, y: -10)

            stackLayer(fillOpacity: 0.30)
                .offset(x: -7, y: -4)

            frontStackLayer
        }
    }

    private func stackLayer(fillOpacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(fillOpacity))
            .frame(width: 84, height: 108)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    private var frontStackLayer: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(frontLayerBackground)
            .frame(width: 88, height: 112)
            .overlay {
                frontLayerVisual
                    .padding(12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.20), radius: 12, y: 5)
    }

    private var frontLayerBackground: Color {
        if case .fileSystem = frontVisualKind {
            return Color.white.opacity(0.97)
        }

        return Color(nsColor: .windowBackgroundColor).opacity(0.94)
    }

    private enum FrontVisualKind {
        case fileSystem(ShelfItem)
        case text
        case url
        case mixed
        case empty
    }

    private var frontVisualKind: FrontVisualKind {
        let items = viewModel.items
        guard items.isEmpty == false else {
            return .empty
        }

        let itemTypes = Set(items.map(\.type))

        if itemTypes.allSatisfy({ $0 == .file || $0 == .folder }), let topItem = items.last {
            return .fileSystem(topItem)
        }

        if itemTypes.count == 1, itemTypes.contains(.text) {
            return .text
        }

        if itemTypes.count == 1, itemTypes.contains(.url) {
            return .url
        }

        return .mixed
    }

    @ViewBuilder
    private var frontLayerVisual: some View {
        switch frontVisualKind {
        case let .fileSystem(item):
            frontFileVisual(for: item)

        case .text:
            genericFrontIcon(systemName: "text.alignleft")

        case .url:
            genericFrontIcon(systemName: "link")

        case .mixed:
            genericFrontIcon(systemName: "square.stack.3d.up.fill")

        case .empty:
            genericFrontIcon(systemName: "tray")
        }
    }

    @ViewBuilder
    private func frontFileVisual(for item: ShelfItem) -> some View {
        if let thumbnailImage = fileThumbnail(for: item) {
            Image(nsImage: thumbnailImage)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else if let originalURL = item.originalURL {
            Image(nsImage: NSWorkspace.shared.icon(forFile: originalURL.path))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            genericFrontIcon(systemName: item.iconSystemName)
        }
    }

    private func genericFrontIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fileThumbnail(for item: ShelfItem) -> NSImage? {
        guard item.type == .file else {
            return nil
        }

        guard
            let fileURL = item.originalURL ?? item.localStoredURL,
            fileURL.isFileURL
        else {
            return nil
        }

        return NSImage(contentsOf: fileURL)
    }

    private var previewState: some View {
        let descriptor = viewModel.previewDescriptor

        return HStack(spacing: 16) {
            ZStack(alignment: .trailing) {
                ForEach(Array((descriptor?.primaryIconNames ?? []).enumerated()), id: \.offset) { index, iconName in
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor.opacity(0.88 - (Double(index) * 0.12)))
                        )
                        .offset(x: CGFloat(index) * 18)
                }
            }
            .frame(width: 88, height: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(descriptor?.summaryTitle ?? "New Shelf")
                    .font(.headline)
                    .lineLimit(1)

                Text(descriptor?.summarySubtitle ?? "Drop to collect")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("Drop onto this preview to create a new shelf")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
    }
}

struct ShelfStackDragSourceView: NSViewRepresentable {
    let items: [ShelfItem]
    let onExternalDropSucceeded: (Set<ShelfItem.ID>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(items: items, onExternalDropSucceeded: onExternalDropSucceeded)
    }

    func makeNSView(context: Context) -> ShelfStackDragSourceNSView {
        let dragSourceView = ShelfStackDragSourceNSView()
        dragSourceView.coordinator = context.coordinator
        return dragSourceView
    }

    func updateNSView(_ nsView: ShelfStackDragSourceNSView, context: Context) {
        context.coordinator.items = items
        context.coordinator.onExternalDropSucceeded = onExternalDropSucceeded
        nsView.coordinator = context.coordinator
    }

    @MainActor
    final class Coordinator {
        var items: [ShelfItem]
        var onExternalDropSucceeded: (Set<ShelfItem.ID>) -> Void

        init(
            items: [ShelfItem],
            onExternalDropSucceeded: @escaping (Set<ShelfItem.ID>) -> Void
        ) {
            self.items = items
            self.onExternalDropSucceeded = onExternalDropSucceeded
        }
    }
}

@MainActor
final class ShelfStackDragSourceNSView: NSView, NSDraggingSource {
    weak var coordinator: ShelfStackDragSourceView.Coordinator?

    private var initialMouseDownEvent: NSEvent?
    private var didBeginDrag = false
    private var activeExportedItemIDs: Set<ShelfItem.ID> = []
    private var didSeeOutsideContext = false
    private var previousWindowMovableByBackground: Bool?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func mouseDown(with event: NSEvent) {
        previousWindowMovableByBackground = window?.isMovableByWindowBackground
        window?.isMovableByWindowBackground = false
        initialMouseDownEvent = event
        didBeginDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard didBeginDrag == false else {
            return
        }

        didBeginDrag = true
        guard let initialMouseDownEvent else {
            return
        }

        beginWholeShelfDrag(with: initialMouseDownEvent)
    }

    override func mouseUp(with event: NSEvent) {
        restoreWindowMovabilityIfNeeded()
        initialMouseDownEvent = nil
        didBeginDrag = false
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        if context == .outsideApplication {
            didSeeOutsideContext = true
        }

        return DragSourceController.sourceOperationMask(
            for: coordinator?.items ?? [],
            context: context
        )
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        let exportedItemIDs = activeExportedItemIDs
        let shouldConsumeAfterExternalDrop = didSeeOutsideContext
            && operation.isEmpty == false
            && exportedItemIDs.isEmpty == false

        resetDragState()

        guard shouldConsumeAfterExternalDrop else {
            return
        }

        // Delay mutation until AppKit has fully unwound the drag session.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.coordinator?.onExternalDropSucceeded(exportedItemIDs)
        }
    }

    private func beginWholeShelfDrag(with event: NSEvent) {
        guard
            let coordinator,
            let payload = DragSourceController.wholeShelfExportPayload(for: coordinator.items)
        else {
            return
        }

        activeExportedItemIDs = payload.itemIDs
        didSeeOutsideContext = false

        let baseFrame = bounds.insetBy(dx: 8, dy: 8)
        let dragItems = payload.pasteboardWriters.enumerated().map { index, writer in
            let dragItem = NSDraggingItem(pasteboardWriter: writer)
            let cappedIndex = min(index, 2)
            let offset = CGFloat(cappedIndex) * 3
            let dragFrame = baseFrame.offsetBy(dx: offset, dy: -offset)
            dragItem.setDraggingFrame(dragFrame, contents: Self.dragImage)
            return dragItem
        }

        let session = beginDraggingSession(with: dragItems, event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    private func resetDragState() {
        restoreWindowMovabilityIfNeeded()
        activeExportedItemIDs.removeAll()
        didSeeOutsideContext = false
        initialMouseDownEvent = nil
        didBeginDrag = false
    }

    private func restoreWindowMovabilityIfNeeded() {
        guard let previousWindowMovableByBackground else {
            return
        }

        window?.isMovableByWindowBackground = previousWindowMovableByBackground
        self.previousWindowMovableByBackground = nil
    }

    private static let dragImage: NSImage = {
        let size = NSSize(width: 72, height: 72)
        let image = NSImage(size: size)

        image.lockFocus()

        let cardRect = NSRect(x: 8, y: 8, width: 56, height: 56)
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 14, yRadius: 14)

        NSColor.windowBackgroundColor.withAlphaComponent(0.95).setFill()
        cardPath.fill()

        NSColor.black.withAlphaComponent(0.1).setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()

        if let symbol = NSImage(systemSymbolName: "square.stack.3d.up.fill", accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
            let configuredSymbol = symbol.withSymbolConfiguration(config) ?? symbol
            configuredSymbol.draw(in: NSRect(x: 19, y: 19, width: 34, height: 34))
        }

        image.unlockFocus()
        return image
    }()
}
