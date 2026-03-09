import AppKit

final class ShelfPanel: NSPanel {
    private static let previewStyleMask: NSWindow.StyleMask = [
        .nonactivatingPanel,
        .titled,
        .fullSizeContentView,
        .closable,
        .resizable
    ]

    private static let landedStyleMask: NSWindow.StyleMask = [
        .nonactivatingPanel,
        .borderless
    ]

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    init(frame: NSRect, presentationMode: ShelfPresentationMode) {
        super.init(
            contentRect: frame,
            styleMask: [],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        animationBehavior = .utilityWindow
        isReleasedWhenClosed = false
        isOpaque = false
        hasShadow = true
        backgroundColor = .clear

        applyPresentationMode(presentationMode)
    }

    func applyPresentationMode(_ presentationMode: ShelfPresentationMode) {
        if presentationMode.isPreview {
            styleMask = Self.previewStyleMask
            titleVisibility = .hidden
            titlebarAppearsTransparent = true
            isMovableByWindowBackground = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true
            standardWindowButton(.zoomButton)?.isHidden = true
        } else {
            styleMask = Self.landedStyleMask
            titleVisibility = .hidden
            titlebarAppearsTransparent = true
            isMovableByWindowBackground = true
            standardWindowButton(.closeButton)?.isHidden = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true
            standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}
