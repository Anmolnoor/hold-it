import AppKit
import SwiftUI

struct ShelfItemsTableView: NSViewRepresentable {
    @ObservedObject var viewModel: ShelfViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        let tableView = ShelfTableView()
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.focusRingType = .none
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 12)
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.rowSizeStyle = .large
        tableView.floatsGroupRows = false
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.onCommandA = { [weak coordinator = context.coordinator] in
            coordinator?.selectAll()
        }
        tableView.dragCoordinator = context.coordinator

        let column = NSTableColumn(identifier: .init("ShelfItemsColumn"))
        column.isEditable = false
        tableView.addTableColumn(column)

        scrollView.documentView = tableView

        context.coordinator.tableView = tableView
        context.coordinator.apply(viewModel: viewModel, forceRowReload: true)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.apply(viewModel: viewModel)
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var viewModel: ShelfViewModel
        weak var tableView: ShelfTableView?

        private var isSyncingSelection = false
        private var currentDragItems: [ShelfItem] = []
        private var currentDragItemIDs: Set<ShelfItem.ID> = []
        private var didSeeOutsideDragContext = false
        private var renderedItems: [ShelfItem] = []
        private var renderedSelectionIDs: Set<ShelfItem.ID> = []

        init(viewModel: ShelfViewModel) {
            self.viewModel = viewModel
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            viewModel.items.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            78
        }

        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            true
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let identifier = ShelfItemsTableCellView.reuseIdentifier
            let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? ShelfItemsTableCellView
                ?? ShelfItemsTableCellView(frame: .zero)

            guard row < viewModel.items.count else {
                return cellView
            }

            let item = viewModel.items[row]
            cellView.configure(item: item, isSelected: viewModel.isSelected(item))
            return cellView
        }

        func tableViewSelectionDidChange(_ notification: Notification) {
            guard
                isSyncingSelection == false,
                let tableView
            else {
                return
            }

            let selectedIDs = Set<ShelfItem.ID>(tableView.selectedRowIndexes.compactMap { index in
                guard viewModel.items.indices.contains(index) else {
                    return nil
                }

                return viewModel.items[index].id
            })

            viewModel.setSelection(ids: selectedIDs)
            renderedSelectionIDs = viewModel.selectedItemIDs
            refreshVisibleRows()
        }

        func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
            guard viewModel.items.indices.contains(row) else {
                return nil
            }

            let item = viewModel.items[row]
            currentDragItems = viewModel.draggedItems(anchorID: item.id)
            currentDragItemIDs = Set(currentDragItems.map(\.id))
            return DragSourceController.pasteboardWriter(for: item)
        }

        func tableView(
            _ tableView: NSTableView,
            draggingSession session: NSDraggingSession,
            willBeginAt screenPoint: NSPoint,
            forRowIndexes rowIndexes: IndexSet
        ) {
            didSeeOutsideDragContext = false
            currentDragItems = rowIndexes.compactMap { row in
                guard viewModel.items.indices.contains(row) else {
                    return nil
                }

                return viewModel.items[row]
            }
            currentDragItemIDs = Set(currentDragItems.map(\.id))
        }

        func tableView(
            _ tableView: NSTableView,
            draggingSession session: NSDraggingSession,
            endedAt screenPoint: NSPoint,
            operation: NSDragOperation
        ) {
            let movedItemIDs = currentDragItemIDs
            let shouldConsumeExportedItems = didSeeOutsideDragContext
                && operation.isEmpty == false
                && movedItemIDs.isEmpty == false
            currentDragItems.removeAll()
            currentDragItemIDs.removeAll()
            didSeeOutsideDragContext = false

            // Let AppKit finish unwinding the drag session before reloading the source table.
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                if shouldConsumeExportedItems {
                    self.viewModel.consumeExportedItemsAndCloseIfEmpty(ids: movedItemIDs)
                }

                self.apply(viewModel: self.viewModel, forceRowReload: true)
            }
        }

        func sourceOperationMask(for context: NSDraggingContext) -> NSDragOperation {
            if context == .outsideApplication {
                didSeeOutsideDragContext = true
            }

            let dragItems = currentDragItems.isEmpty
                ? viewModel.items(for: viewModel.selectedItemIDs)
                : currentDragItems

            return DragSourceController.sourceOperationMask(for: dragItems, context: context)
        }

        func selectAll() {
            viewModel.selectAll()
            renderedSelectionIDs = viewModel.selectedItemIDs
            syncSelectionFromModel()
        }

        func apply(viewModel: ShelfViewModel, forceRowReload: Bool = false) {
            self.viewModel = viewModel

            let itemsChanged = renderedItems != viewModel.items
            let selectionChanged = renderedSelectionIDs != viewModel.selectedItemIDs

            renderedItems = viewModel.items
            renderedSelectionIDs = viewModel.selectedItemIDs

            if itemsChanged || forceRowReload {
                tableView?.reloadData()
            }

            if itemsChanged || selectionChanged || forceRowReload {
                syncSelectionFromModel()
            }
        }

        private func syncSelectionFromModel() {
            guard let tableView else {
                return
            }

            let rowIndexes = IndexSet(
                viewModel.items.enumerated().compactMap { index, item in
                    viewModel.selectedItemIDs.contains(item.id) ? index : nil
                }
            )

            if tableView.selectedRowIndexes != rowIndexes {
                isSyncingSelection = true
                tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
                isSyncingSelection = false
            }

            refreshVisibleRows()
        }

        private func refreshVisibleRows() {
            guard let tableView else {
                return
            }

            let visibleRows = tableView.rows(in: tableView.visibleRect)
            guard visibleRows.length > 0 else {
                return
            }

            let rowRange = visibleRows.location..<(visibleRows.location + visibleRows.length)
            for row in rowRange where viewModel.items.indices.contains(row) {
                guard
                    let cellView = tableView.view(
                        atColumn: 0,
                        row: row,
                        makeIfNecessary: false
                    ) as? ShelfItemsTableCellView
                else {
                    continue
                }

                let item = viewModel.items[row]
                cellView.configure(item: item, isSelected: viewModel.isSelected(item))
            }
        }
    }
}

@MainActor
final class ShelfTableView: NSTableView {
    var onCommandA: (() -> Void)?
    weak var dragCoordinator: ShelfItemsTableView.Coordinator?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let normalizedFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if normalizedFlags == .command, event.charactersIgnoringModifiers?.lowercased() == "a" {
            onCommandA?()
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        dragCoordinator?.sourceOperationMask(for: context) ?? .copy
    }
}

@MainActor
final class ShelfItemsTableCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("ShelfItemsTableCellView")

    private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.reuseIdentifier
        wantsLayer = true
        configureHostingView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: ShelfItem, isSelected: Bool) {
        hostingView.rootView = AnyView(
            ShelfItemView(
                item: item,
                isSelected: isSelected
            )
        )
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
}
