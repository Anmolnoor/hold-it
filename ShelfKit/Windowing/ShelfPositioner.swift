import AppKit

enum ShelfPositioner {
    static func initialFrame(for size: CGSize, index: Int) -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        let visibleFrame = visibleFrame(near: mouseLocation)
        let cascadeOffset = CGFloat(index % 8) * 18

        let width = size.width
        let height = size.height
        let minX = visibleFrame.minX + 20
        let maxX = visibleFrame.maxX - width - 20
        let minY = visibleFrame.minY + 20
        let maxY = visibleFrame.maxY - height - 20

        let centeredX = mouseLocation.x - (width / 2) + cascadeOffset
        let centeredY = mouseLocation.y - (height / 2) - cascadeOffset

        let x = min(max(centeredX, minX), maxX)
        let y = min(max(centeredY, minY), maxY)

        return NSRect(x: x, y: y, width: width, height: height)
    }

    static func previewFrame(near point: CGPoint, size: CGSize) -> NSRect {
        let visibleFrame = visibleFrame(near: point)
        let width = size.width
        let height = size.height
        let x = min(
            max(point.x - (width / 2), visibleFrame.minX + 20),
            visibleFrame.maxX - width - 20
        )

        let preferredY = point.y - height - 26
        let fallbackY = point.y + 26
        let y = preferredY >= visibleFrame.minY + 20
            ? preferredY
            : min(fallbackY, visibleFrame.maxY - height - 20)

        return NSRect(x: x, y: y, width: width, height: height)
    }

    static func dragPreviewFrame(under point: CGPoint, size: CGSize) -> NSRect {
        let visibleFrame = visibleFrame(near: point)
        let width = size.width
        let height = size.height
        let x = min(
            max(point.x - (width / 2), visibleFrame.minX + 20),
            visibleFrame.maxX - width - 20
        )
        let y = min(
            max(point.y - height + min(44, height / 2), visibleFrame.minY + 20),
            visibleFrame.maxY - height - 20
        )

        return NSRect(x: x, y: y, width: width, height: height)
    }

    static func topLeftFrame(near point: CGPoint, size: CGSize) -> NSRect {
        let visibleFrame = visibleFrame(near: point)
        let x = visibleFrame.minX + 20
        let y = visibleFrame.maxY - size.height - 20

        return NSRect(origin: CGPoint(x: x, y: y), size: size)
    }

    private static func visibleFrame(near point: CGPoint) -> NSRect {
        let availableScreens = NSScreen.screens
        let screen = availableScreens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main ?? availableScreens.first
        return screen?.visibleFrame ?? NSRect(origin: .zero, size: CGSize(width: 360, height: 420))
    }
}
