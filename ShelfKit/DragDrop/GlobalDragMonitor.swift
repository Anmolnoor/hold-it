import AppKit

final class GlobalDragMonitor {
    var onShakeDetected: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    private struct ActiveDragSession {
        var didTriggerPreview: Bool
    }

    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?
    private var activeDragSession: ActiveDragSession?
    private var shakeDetector = ShakeDetector()

    func start() {
        guard dragMonitor == nil, mouseUpMonitor == nil else {
            return
        }

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            self?.handleDragged(event)
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.endActiveDrag()
        }
    }

    func stop() {
        if let dragMonitor {
            NSEvent.removeMonitor(dragMonitor)
            self.dragMonitor = nil
        }

        if let mouseUpMonitor {
            NSEvent.removeMonitor(mouseUpMonitor)
            self.mouseUpMonitor = nil
        }

        endActiveDrag()
    }

    deinit {
        stop()
    }

    private func handleDragged(_ event: NSEvent) {
        if activeDragSession == nil {
            activeDragSession = ActiveDragSession(
                didTriggerPreview: false
            )
            shakeDetector.reset()
        }

        let cursorLocation = NSEvent.mouseLocation
        let didShake = shakeDetector.ingest(
            point: cursorLocation,
            timestamp: event.timestamp
        )

        guard
            didShake,
            activeDragSession?.didTriggerPreview == false
        else {
            return
        }

        activeDragSession?.didTriggerPreview = true
        onShakeDetected?(cursorLocation)
    }

    private func endActiveDrag() {
        guard activeDragSession != nil else {
            return
        }

        activeDragSession = nil
        shakeDetector.reset()
        onDragEnded?()
    }
}
