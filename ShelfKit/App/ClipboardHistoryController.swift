import AppKit
import Combine

@MainActor
final class ClipboardHistoryController {
    private let store: ClipboardHistoryStore
    private let preferences: PreferencesStore
    private let pasteboard: NSPasteboard
    private let pollInterval: TimeInterval

    private var timer: Timer?
    private var preferenceCancellable: AnyCancellable?
    private var lastChangeCount: Int

    init(
        store: ClipboardHistoryStore,
        preferences: PreferencesStore,
        pasteboard: NSPasteboard = .general,
        pollInterval: TimeInterval = 0.75
    ) {
        self.store = store
        self.preferences = preferences
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        preferenceCancellable = preferences.$clipboardHistoryEnabled
            .sink { [weak self] isEnabled in
                self?.setMonitoringEnabled(isEnabled)
            }
    }

    func stop() {
        preferenceCancellable = nil
        setMonitoringEnabled(false)
    }

    private func setMonitoringEnabled(_ isEnabled: Bool) {
        if isEnabled {
            guard timer == nil else {
                return
            }

            lastChangeCount = pasteboard.changeCount
            timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.captureIfPasteboardChanged()
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
            lastChangeCount = pasteboard.changeCount
        }
    }

    private func captureIfPasteboardChanged() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = changeCount
        store.captureCurrentPasteboard(pasteboard)
    }
}
