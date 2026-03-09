import AppKit

enum DropReceiver {
    static let supportedDraggedTypes: [NSPasteboard.PasteboardType] = [
        .fileURL,
        .URL,
        .string
    ]

    static func canRead(_ pasteboard: NSPasteboard) -> Bool {
        previewDescriptor(from: pasteboard) != nil
    }

    static func previewDescriptor(from pasteboard: NSPasteboard) -> DragPreviewDescriptor? {
        let previewItems = previewItems(from: pasteboard)
        guard previewItems.isEmpty == false else {
            return nil
        }

        return DragPreviewDescriptor(previewItems: previewItems)
    }

    static func items(from pasteboard: NSPasteboard) -> [ShelfItem] {
        var results: [ShelfItem] = []
        var seenURLs = Set<String>()
        var seenStrings = Set<String>()

        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            for url in fileURLs {
                let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
                let item = ShelfItem(fileURL: url, isDirectory: resourceValues?.isDirectory ?? false)
                results.append(item)
                seenURLs.insert(url.absoluteString)
            }
        }

        if let allURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: false]
        ) as? [URL] {
            for url in allURLs where url.isFileURL == false {
                guard seenURLs.insert(url.absoluteString).inserted else {
                    continue
                }

                results.append(ShelfItem(url: url))
            }
        }

        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
            for string in strings {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.isEmpty == false else {
                    continue
                }

                if seenStrings.insert(trimmed).inserted == false {
                    continue
                }

                if let url = URL(string: trimmed), url.scheme != nil {
                    guard seenURLs.insert(url.absoluteString).inserted else {
                        continue
                    }

                    results.append(ShelfItem(url: url))
                } else {
                    results.append(ShelfItem(text: trimmed))
                }
            }
        }

        return results
    }

    private static func previewItems(from pasteboard: NSPasteboard) -> [DragPreviewItem] {
        guard let pasteboardItems = pasteboard.pasteboardItems else {
            return []
        }

        var results: [DragPreviewItem] = []
        var seenEntries = Set<String>()

        for pasteboardItem in pasteboardItems {
            guard let previewItem = previewItem(from: pasteboardItem) else {
                continue
            }

            guard seenEntries.insert(previewItem.identifier).inserted else {
                continue
            }

            results.append(previewItem.item)
        }

        return results
    }

    private static func previewItem(from pasteboardItem: NSPasteboardItem) -> (identifier: String, item: DragPreviewItem)? {
        if
            let rawURL = stringValue(for: [.fileURL, .URL], from: pasteboardItem),
            let url = URL(string: rawURL),
            url.isFileURL
        {
            let displayName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
            let fallbackTitle = displayName.isEmpty ? "File" : displayName
            return (
                identifier: "file:\(url.absoluteString)",
                item: DragPreviewItem(title: fallbackTitle, kind: .file)
            )
        }

        if
            let rawURL = stringValue(for: [.URL], from: pasteboardItem),
            let url = URL(string: rawURL),
            url.isFileURL == false
        {
            return (
                identifier: "url:\(url.absoluteString)",
                item: DragPreviewItem(title: url.host ?? url.absoluteString, kind: .url)
            )
        }

        if let string = stringValue(for: [.string], from: pasteboardItem) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false else {
                return nil
            }

            if
                let url = URL(string: trimmed),
                url.scheme != nil,
                url.isFileURL == false
            {
                return (
                    identifier: "url:\(url.absoluteString)",
                    item: DragPreviewItem(title: url.host ?? url.absoluteString, kind: .url)
                )
            }

            let preview = String(trimmed.prefix(80))
            let title = preview.isEmpty ? "Text Clip" : preview
            return (
                identifier: "text:\(trimmed)",
                item: DragPreviewItem(title: title, kind: .text)
            )
        }

        return nil
    }

    private static func stringValue(
        for types: [NSPasteboard.PasteboardType],
        from pasteboardItem: NSPasteboardItem
    ) -> String? {
        for type in types {
            if let string = pasteboardItem.string(forType: type) {
                return string
            }

            if
                let data = pasteboardItem.data(forType: type),
                let string = String(data: data, encoding: .utf8)
            {
                return string
            }
        }

        return nil
    }
}
