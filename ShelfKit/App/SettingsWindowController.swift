import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(
        preferencesStore: PreferencesStore,
        clipboardHistoryStore: ClipboardHistoryStore,
        updateController: UpdateController,
        createShelfAction: @escaping () -> Void
    ) {
        let rootView = SettingsView(
            preferences: preferencesStore,
            clipboardHistoryStore: clipboardHistoryStore,
            updateController: updateController,
            createShelf: createShelfAction
        )
        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "HoldIt Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 460, height: 360))
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
