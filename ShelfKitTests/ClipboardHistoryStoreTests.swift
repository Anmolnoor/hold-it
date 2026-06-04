import XCTest
import AppKit
@testable import ShelfKit

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    func testStorePersistsNewestTwentyItemsAcrossInstances() throws {
        let directory = try temporaryDirectory()
        let store = ClipboardHistoryStore(directory: directory)

        for index in 0..<22 {
            store.add(
                ClipboardHistoryItem(
                    kind: .text,
                    displayTitle: "Clip \(index)",
                    displaySubtitle: "Plain text",
                    textValue: "Clip \(index)",
                    signature: "text:\(index)"
                )
            )
        }

        let restored = ClipboardHistoryStore(directory: directory)

        XCTAssertEqual(restored.items.count, 20)
        XCTAssertEqual(restored.items.first?.displayTitle, "Clip 21")
        XCTAssertEqual(restored.items.last?.displayTitle, "Clip 2")
    }

    func testCaptureCurrentPasteboardAddsTextItem() throws {
        let pasteboard = makePasteboard()
        pasteboard.setString("hello clipboard", forType: .string)
        let store = ClipboardHistoryStore(directory: try temporaryDirectory())

        store.captureCurrentPasteboard(pasteboard)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.kind, .text)
        XCTAssertEqual(store.items.first?.displayTitle, "hello clipboard")
        XCTAssertEqual(store.items.first?.textValue, "hello clipboard")
    }

    func testCaptureCurrentPasteboardTreatsURLStringAsURL() throws {
        let pasteboard = makePasteboard()
        pasteboard.setString("https://example.com/path", forType: .string)
        let store = ClipboardHistoryStore(directory: try temporaryDirectory())

        store.captureCurrentPasteboard(pasteboard)

        XCTAssertEqual(store.items.first?.kind, .url)
        XCTAssertEqual(store.items.first?.url?.absoluteString, "https://example.com/path")
    }

    func testCaptureCurrentPasteboardAddsFileReference() throws {
        let fileURL = try temporaryDirectory().appendingPathComponent("clip.txt")
        try "file".write(to: fileURL, atomically: true, encoding: .utf8)
        let pasteboard = makePasteboard()
        XCTAssertTrue(pasteboard.writeObjects([fileURL as NSURL]))
        let store = ClipboardHistoryStore(directory: try temporaryDirectory())

        store.captureCurrentPasteboard(pasteboard)

        XCTAssertEqual(store.items.first?.kind, .file)
        XCTAssertEqual(store.items.first?.fileURLs, [fileURL])
    }

    func testCaptureCurrentPasteboardPersistsImageFile() throws {
        let pasteboard = makePasteboard()
        XCTAssertTrue(pasteboard.writeObjects([makeImage()]))
        let store = ClipboardHistoryStore(directory: try temporaryDirectory())

        store.captureCurrentPasteboard(pasteboard)

        let item = try XCTUnwrap(store.items.first)
        let imageURL = try XCTUnwrap(store.imageURL(for: item))
        XCTAssertEqual(item.kind, .image)
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageURL.path))
    }

    func testCopyTextItemWritesToPasteboard() throws {
        let pasteboard = makePasteboard()
        let store = ClipboardHistoryStore(directory: try temporaryDirectory())
        let item = ClipboardHistoryItem(
            kind: .text,
            displayTitle: "copy me",
            displaySubtitle: "Plain text",
            textValue: "copy me",
            signature: "text:copy me"
        )

        XCTAssertTrue(store.copyToPasteboard(item, pasteboard: pasteboard))

        XCTAssertEqual(pasteboard.string(forType: .string), "copy me")
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("holdit-clipboard-tests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        return pasteboard
    }

    private func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 12, height: 8))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: 12, height: 8).fill()
        image.unlockFocus()
        return image
    }
}
