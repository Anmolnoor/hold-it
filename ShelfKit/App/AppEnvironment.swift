import AppKit

@MainActor
final class AppEnvironment {
    let preferencesStore: PreferencesStore
    let shelfCoordinator: ShelfCoordinator
    let updateController: UpdateController

    private let menuBarController: MenuBarController
    private let globalDragMonitor: GlobalDragMonitor
    private let hotkeyController: GlobalHotkeyController
    private let startupUpdateScheduler: StartupUpdateScheduler
    private lazy var settingsWindowController = SettingsWindowController(
        preferencesStore: preferencesStore,
        updateController: updateController,
        createShelfAction: { [weak self] in
            self?.createShelf()
        }
    )

    init() {
        let preferencesStore = PreferencesStore()
        let menuBarController = MenuBarController()
        let globalDragMonitor = GlobalDragMonitor()
        let hotkeyController = GlobalHotkeyController()
        let updateController = UpdateController()

        self.preferencesStore = preferencesStore
        self.shelfCoordinator = ShelfCoordinator(preferencesStore: preferencesStore)
        self.updateController = updateController
        self.menuBarController = menuBarController
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
        startupUpdateScheduler.scheduleIfNeeded()
    }

    func createShelf() {
        shelfCoordinator.createShelf()
    }

    func showSettings() {
        settingsWindowController.present()
    }
}
