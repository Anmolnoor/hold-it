import Combine
import CoreGraphics
import Foundation
import ServiceManagement

@MainActor
final class PreferencesStore: ObservableObject {
    private enum Keys {
        static let shelfWidth = "preferences.shelfWidth"
        static let shelfHeight = "preferences.shelfHeight"
        static let checkForUpdatesAfterLaunch = "preferences.checkForUpdatesAfterLaunch"
    }

    @Published var preferredShelfWidth: Double {
        didSet {
            defaults.set(preferredShelfWidth, forKey: Keys.shelfWidth)
        }
    }

    @Published var preferredShelfHeight: Double {
        didSet {
            defaults.set(preferredShelfHeight, forKey: Keys.shelfHeight)
        }
    }

    @Published var checkForUpdatesAfterLaunch: Bool {
        didSet {
            defaults.set(checkForUpdatesAfterLaunch, forKey: Keys.checkForUpdatesAfterLaunch)
        }
    }

    let newShelfHotkeyDescription = GlobalHotkeyController.Shortcut.newShelf.displayName

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedWidth = defaults.object(forKey: Keys.shelfWidth) as? Double
        let storedHeight = defaults.object(forKey: Keys.shelfHeight) as? Double
        let storedCheckForUpdatesAfterLaunch = defaults.object(forKey: Keys.checkForUpdatesAfterLaunch) as? Bool

        preferredShelfWidth = storedWidth ?? 360
        preferredShelfHeight = storedHeight ?? 420
        checkForUpdatesAfterLaunch = storedCheckForUpdatesAfterLaunch ?? false
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Registration can fail when running unsigned from Xcode.
            }
        }
    }

    var shelfSize: CGSize {
        CGSize(width: preferredShelfWidth, height: preferredShelfHeight)
    }

    func updateShelfSize(_ size: CGSize) {
        preferredShelfWidth = max(300, min(700, size.width))
        preferredShelfHeight = max(240, min(900, size.height))
    }
}
