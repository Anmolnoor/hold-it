import AppKit

@MainActor
final class AppEnvironment {
    let preferencesStore: PreferencesStore
    let shelfCoordinator: ShelfCoordinator

    private let menuBarController: MenuBarController
    private let globalDragMonitor: GlobalDragMonitor
    private let hotkeyController: GlobalHotkeyController
    private lazy var settingsWindowController = SettingsWindowController(
        preferencesStore: preferencesStore,
        createShelfAction: { [weak self] in
            self?.createShelf()
        }
    )

    init() {
        let preferencesStore = PreferencesStore()
        let menuBarController = MenuBarController()
        let globalDragMonitor = GlobalDragMonitor()
        let hotkeyController = GlobalHotkeyController()

        self.preferencesStore = preferencesStore
        self.shelfCoordinator = ShelfCoordinator(preferencesStore: preferencesStore)
        self.menuBarController = menuBarController
        self.globalDragMonitor = globalDragMonitor
        self.hotkeyController = hotkeyController
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
    }

    func createShelf() {
        shelfCoordinator.createShelf()
    }

    func showSettings() {
        settingsWindowController.present()
    }
}
