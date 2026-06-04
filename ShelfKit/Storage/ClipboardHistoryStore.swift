import AppKit
import Combine
import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    static let maximumItemCount = 20

    @Published private(set) var items: [ClipboardHistoryItem]

    private let directory: URL
    private let historyURL: URL
    private let imagesDirectory: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        directory: URL = ClipboardHistoryStore.defaultDirectory(),
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.historyURL = directory.appendingPathComponent("history.json")
        self.imagesDirectory = directory.appendingPathComponent("Images", isDirectory: true)
        self.fileManager = fileManager
        self.items = []

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    @discardableResult
    func add(_ item: ClipboardHistoryItem) -> Bool {
        if items.first?.signature == item.signature {
            return false
        }

        items.insert(item, at: 0)
        trimToMaximumCount()
        save()
        return true
    }

    func clear() {
        items.removeAll()
        save()
        removeStoredImages(excluding: [])
    }

    func imageURL(for item: ClipboardHistoryItem) -> URL? {
        guard let imageInfo = item.imageInfo else {
            return nil
        }

        return imagesDirectory.appendingPathComponent(imageInfo.filename)
    }

    func image(for item: ClipboardHistoryItem) -> NSImage? {
        guard let imageURL = imageURL(for: item) else {
            return nil
        }

        return NSImage(contentsOf: imageURL)
    }

    func captureCurrentPasteboard(_ pasteboard: NSPasteboard = .general) {
        guard let item = item(from: pasteboard) else {
            return
        }

        if add(item) == false, let imageName = item.imageInfo?.filename {
            try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(imageName))
        }
    }

    func copyToPasteboard(
        _ item: ClipboardHistoryItem,
        pasteboard: NSPasteboard = .general
    ) -> Bool {
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            guard let textValue = item.textValue else {
                return false
            }

            return pasteboard.setString(textValue, forType: .string)

        case .url:
            guard let url = item.url else {
                return false
            }

            return pasteboard.writeObjects([url as NSURL])

        case .file, .folder, .mixed:
            let urls = item.fileURLs.map { $0 as NSURL }
            guard urls.isEmpty == false else {
                return false
            }

            return pasteboard.writeObjects(urls)

        case .image:
            guard let image = image(for: item) else {
                return false
            }

            return pasteboard.writeObjects([image])
        }
    }

    private func load() {
        do {
            try fileManager.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true
            )

            guard fileManager.fileExists(atPath: historyURL.path) else {
                items = []
                return
            }

            let data = try Data(contentsOf: historyURL)
            items = try decoder.decode([ClipboardHistoryItem].self, from: data)
            trimToMaximumCount()
            removeStoredImages(excluding: Set(items.compactMap(\.imageInfo?.filename)))
        } catch {
            items = []
        }
    }

    private func save() {
        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            let data = try encoder.encode(items)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            // Clipboard history should never interrupt the menu bar app.
        }
    }

    private func trimToMaximumCount() {
        guard items.count > Self.maximumItemCount else {
            return
        }

        let removedItems = items.dropFirst(Self.maximumItemCount)
        items = Array(items.prefix(Self.maximumItemCount))
        let retainedImageNames = Set(items.compactMap(\.imageInfo?.filename))
        let removedImageNames = Set(removedItems.compactMap(\.imageInfo?.filename))
        removeStoredImages(excluding: retainedImageNames, candidates: removedImageNames)
    }

    private func removeStoredImages(
        excluding retainedImageNames: Set<String>,
        candidates: Set<String>? = nil
    ) {
        let imageNames: Set<String>
        if let candidates {
            imageNames = candidates
        } else {
            let storedImageURLs = (try? fileManager.contentsOfDirectory(
                at: imagesDirectory,
                includingPropertiesForKeys: nil
            )) ?? []
            imageNames = Set(storedImageURLs.map(\.lastPathComponent))
        }

        for imageName in imageNames where retainedImageNames.contains(imageName) == false {
            try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(imageName))
        }
    }

    private func item(from pasteboard: NSPasteboard) -> ClipboardHistoryItem? {
        if let fileItem = fileItem(from: pasteboard) {
            return fileItem
        }

        if let imageItem = imageItem(from: pasteboard) {
            return imageItem
        }

        if let urlItem = urlItem(from: pasteboard) {
            return urlItem
        }

        if let textItem = textItem(from: pasteboard) {
            return textItem
        }

        return nil
    }

    private func fileItem(from pasteboard: NSPasteboard) -> ClipboardHistoryItem? {
        guard
            let fileURLs = pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL],
            fileURLs.isEmpty == false
        else {
            return nil
        }

        let signature = "files:" + fileURLs.map(\.absoluteString).joined(separator: "\n")
        if fileURLs.count == 1, let fileURL = fileURLs.first {
            let isDirectory = isDirectory(fileURL)
            let displayTitle = fileURL.lastPathComponent.isEmpty ? fileURL.path : fileURL.lastPathComponent
            return ClipboardHistoryItem(
                kind: isDirectory ? .folder : .file,
                displayTitle: displayTitle,
                displaySubtitle: fileURL.path,
                fileURLs: fileURLs,
                signature: signature
            )
        }

        return ClipboardHistoryItem(
            kind: .mixed,
            displayTitle: "\(fileURLs.count) items",
            displaySubtitle: "Files and folders",
            fileURLs: fileURLs,
            signature: signature
        )
    }

    private func imageItem(from pasteboard: NSPasteboard) -> ClipboardHistoryItem? {
        guard
            let image = NSImage(pasteboard: pasteboard),
            let pngData = pngData(from: image)
        else {
            return nil
        }

        let signature = "image:\(stableHash(for: pngData))"
        guard items.first?.signature != signature else {
            return nil
        }

        let filename = "\(UUID().uuidString).png"
        let imageURL = imagesDirectory.appendingPathComponent(filename)

        do {
            try fileManager.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true
            )
            try pngData.write(to: imageURL, options: .atomic)
        } catch {
            return nil
        }

        return ClipboardHistoryItem(
            kind: .image,
            displayTitle: "Image",
            displaySubtitle: "\(Int(image.size.width)) x \(Int(image.size.height))",
            imageInfo: ClipboardHistoryImageInfo(
                filename: filename,
                width: Double(image.size.width),
                height: Double(image.size.height)
            ),
            signature: signature
        )
    }

    private func urlItem(from pasteboard: NSPasteboard) -> ClipboardHistoryItem? {
        guard
            let urls = pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: false]
            ) as? [URL],
            let url = urls.first(where: { $0.isFileURL == false })
        else {
            return nil
        }

        return ClipboardHistoryItem(
            kind: .url,
            displayTitle: url.host ?? url.absoluteString,
            displaySubtitle: url.absoluteString,
            url: url,
            signature: "url:\(url.absoluteString)"
        )
    }

    private func textItem(from pasteboard: NSPasteboard) -> ClipboardHistoryItem? {
        guard let string = pasteboard.string(forType: .string) else {
            return nil
        }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }

        if let url = URL(string: trimmed), url.scheme != nil, url.isFileURL == false {
            return ClipboardHistoryItem(
                kind: .url,
                displayTitle: url.host ?? url.absoluteString,
                displaySubtitle: url.absoluteString,
                url: url,
                signature: "url:\(url.absoluteString)"
            )
        }

        let preview = String(trimmed.prefix(80))
        return ClipboardHistoryItem(
            kind: .text,
            displayTitle: preview.isEmpty ? "Text Clip" : preview,
            displaySubtitle: "Plain text",
            textValue: trimmed,
            signature: "text:\(trimmed)"
        )
    }

    private func pngData(from image: NSImage) -> Data? {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }

    private func stableHash(for data: Data) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211

        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return String(hash, radix: 16)
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    private nonisolated static func defaultDirectory() -> URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return baseURL
            .appendingPathComponent("HoldIt", isDirectory: true)
            .appendingPathComponent("ClipboardHistory", isDirectory: true)
    }
}
