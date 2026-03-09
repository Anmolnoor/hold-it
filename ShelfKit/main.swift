import AppKit

let delegate = MainActor.assumeIsolated {
    AppDelegate()
}
let application = NSApplication.shared
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
