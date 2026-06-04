import AppKit

@MainActor
final class MenuBarController: NSObject {
    var onNewShelf: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    override init() {
        super.init()
        configureStatusItem()
        configureMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "shippingbox", accessibilityDescription: "HoldIt")
        button.imagePosition = .imageOnly
        button.toolTip = "HoldIt"
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(title: "New Shelf", action: #selector(newShelf), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit HoldIt", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }
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
}
