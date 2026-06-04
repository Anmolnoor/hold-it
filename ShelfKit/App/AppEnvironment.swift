import AppKit

@MainActor
final class AppEnvironment {
    let preferencesStore: PreferencesStore
    let clipboardHistoryStore: ClipboardHistoryStore
    let shelfCoordinator: ShelfCoordinator
    let updateController: UpdateController

    private let menuBarController: MenuBarController
    private let clipboardHistoryController: ClipboardHistoryController
    private let globalDragMonitor: GlobalDragMonitor
    private let hotkeyController: GlobalHotkeyController
    private let startupUpdateScheduler: StartupUpdateScheduler
    private lazy var settingsWindowController = SettingsWindowController(
        preferencesStore: preferencesStore,
        clipboardHistoryStore: clipboardHistoryStore,
        updateController: updateController,
        createShelfAction: { [weak self] in
            self?.createShelf()
        }
    )

    init() {
        let preferencesStore = PreferencesStore()
        let clipboardHistoryStore = ClipboardHistoryStore()
        let menuBarController = MenuBarController(
            clipboardHistoryStore: clipboardHistoryStore,
            preferencesStore: preferencesStore
        )
        let globalDragMonitor = GlobalDragMonitor()
        let hotkeyController = GlobalHotkeyController()
        let updateController = UpdateController()

        self.preferencesStore = preferencesStore
        self.clipboardHistoryStore = clipboardHistoryStore
        self.shelfCoordinator = ShelfCoordinator(preferencesStore: preferencesStore)
        self.updateController = updateController
        self.menuBarController = menuBarController
        self.clipboardHistoryController = ClipboardHistoryController(
            store: clipboardHistoryStore,
            preferences: preferencesStore
        )
        self.globalDragMonitor = globalDragMonitor
        self.hotkeyController = hotkeyController
        self.startupUpdateScheduler = StartupUpdateScheduler(
            preferences: preferencesStore,
            checkForUpdates: {
                await updateController.checkForUpdates()
            }
        )
    }

    func start() {
        menuBarController.onNewShelf = { [weak self] in
            self?.createShelf()
        }

        menuBarController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }

        menuBarController.onQuit = {
            NSApp.terminate(nil)
        }

        hotkeyController.registerNewShelfHotKey { [weak self] in
            self?.createShelf()
        }

        globalDragMonitor.onShakeDetected = { [weak self] cursorLocation in
            self?.shelfCoordinator.createPreviewShelf(
                near: cursorLocation
            )
        }

        globalDragMonitor.onDragEnded = { [weak self] in
            self?.shelfCoordinator.handleGlobalDragEnded()
        }

        globalDragMonitor.start()
        if isRunningUnitTests == false {
            clipboardHistoryController.start()
        }
        startupUpdateScheduler.scheduleIfNeeded()

        DispatchQueue.main.async { [weak self] in
            self?.showClipboardHistoryNoticeIfNeeded()
        }
    }

    func createShelf() {
        shelfCoordinator.createShelf()
    }

    func showSettings() {
        settingsWindowController.present()
    }

    private func showClipboardHistoryNoticeIfNeeded() {
        guard isRunningUnitTests == false else {
            return
        }

        guard
            preferencesStore.clipboardHistoryEnabled,
            preferencesStore.hasSeenClipboardHistoryNotice == false
        else {
            return
        }

        preferencesStore.hasSeenClipboardHistoryNotice = true

        let alert = NSAlert()
        alert.messageText = "Clipboard History is on"
        alert.informativeText = """
        HoldIt now keeps your 20 most recent clipboard items, including text, links, files, and images, so they are available from the menu bar. You can turn Clipboard History off at any time in Settings.
        """
        alert.addButton(withTitle: "Got It")
        alert.addButton(withTitle: "Open Settings")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            showSettings()
        }
    }

    private var isRunningUnitTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
