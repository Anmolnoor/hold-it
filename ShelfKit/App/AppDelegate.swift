import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let environment = AppEnvironment()
        environment.start()
        self.environment = environment
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard flag == false else {
            return false
        }

        environment?.createShelf()
        return false
    }
}
