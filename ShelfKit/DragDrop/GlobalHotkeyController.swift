import Carbon.HIToolbox
import Foundation

private let shelfHotKeySignature: OSType = 0x53484C46
private let shelfHotKeyIdentifier: UInt32 = 1

final class GlobalHotkeyController {
    struct Shortcut {
        let keyCode: UInt32
        let modifiers: UInt32
        let displayName: String

        static let newShelf = Shortcut(
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(cmdKey | optionKey),
            displayName: "Option-Command-S"
        )
    }

    private static let eventHandler: EventHandlerUPP = { _, event, userData in
        guard
            let event,
            let userData
        else {
            return noErr
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        guard
            hotKeyID.signature == shelfHotKeySignature,
            hotKeyID.id == shelfHotKeyIdentifier
        else {
            return noErr
        }

        let controller = Unmanaged<GlobalHotkeyController>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
            controller.handler?()
        }

        return noErr
    }

    private var handler: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func registerNewShelfHotKey(handler: @escaping () -> Void) {
        self.handler = handler
        unregister()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = shelfHotKeySignature
        hotKeyID.id = shelfHotKeyIdentifier

        RegisterEventHotKey(
            Shortcut.newShelf.keyCode,
            Shortcut.newShelf.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}
