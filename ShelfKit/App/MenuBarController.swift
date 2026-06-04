import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    var onNewShelf: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let clipboardHistoryStore: ClipboardHistoryStore
    private let preferencesStore: PreferencesStore

    private lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 460)
        popover.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView(
                store: clipboardHistoryStore,
                preferences: preferencesStore,
                onSelect: { [weak self] item in
                    self?.copyHistoryItemAndClose(item)
                },
                onNewShelf: { [weak self] in
                    self?.newShelf(nil)
                },
                onOpenSettings: { [weak self] in
                    self?.openSettings(nil)
                },
                onQuit: { [weak self] in
                    self?.quit(nil)
                }
            )
        )
        return popover
    }()

    init(
        clipboardHistoryStore: ClipboardHistoryStore,
        preferencesStore: PreferencesStore
    ) {
        self.clipboardHistoryStore = clipboardHistoryStore
        self.preferencesStore = preferencesStore
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "shippingbox", accessibilityDescription: "HoldIt")
        button.imagePosition = .imageOnly
        button.toolTip = "HoldIt"
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc
    private func newShelf(_ sender: Any?) {
        onNewShelf?()
    }

    @objc
    private func openSettings(_ sender: Any?) {
        onOpenSettings?()
    }

    @objc
    private func quit(_ sender: Any?) {
        onQuit?()
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func copyHistoryItemAndClose(_ item: ClipboardHistoryItem) {
        _ = clipboardHistoryStore.copyToPasteboard(item)
        popover.performClose(nil)
    }
}
