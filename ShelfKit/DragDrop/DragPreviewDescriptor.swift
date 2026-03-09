import Foundation

enum DragPreviewItemKind: Equatable {
    case file
    case folder
    case text
    case url
}

struct DragPreviewItem: Equatable {
    let title: String
    let kind: DragPreviewItemKind

    init(title: String, kind: DragPreviewItemKind) {
        self.title = title
        self.kind = kind
    }

    init(item: ShelfItem) {
        switch item.type {
        case .file:
            self.init(title: item.displayName, kind: .file)
        case .folder:
            self.init(title: item.displayName, kind: .folder)
        case .text:
            self.init(title: item.displayName, kind: .text)
        case .url:
            self.init(title: item.displayName, kind: .url)
        }
    }

    var iconSystemName: String {
        switch kind {
        case .file:
            return "doc"
        case .folder:
            return "folder"
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        }
    }

    var isFileSystemItem: Bool {
        kind == .file || kind == .folder
    }
}

struct DragPreviewDescriptor: Equatable {
    let itemCount: Int
    let primaryIconNames: [String]
    let summaryTitle: String
    let summarySubtitle: String

    init(
        itemCount: Int,
        primaryIconNames: [String],
        summaryTitle: String,
        summarySubtitle: String
    ) {
        self.itemCount = itemCount
        self.primaryIconNames = primaryIconNames
        self.summaryTitle = summaryTitle
        self.summarySubtitle = summarySubtitle
    }

    init(items: [ShelfItem]) {
        self.init(previewItems: items.map(DragPreviewItem.init(item:)))
    }

    init(previewItems: [DragPreviewItem]) {
        itemCount = previewItems.count
        primaryIconNames = Array(previewItems.prefix(3).map(\.iconSystemName))

        if let firstItem = previewItems.first, previewItems.count == 1 {
            summaryTitle = firstItem.title
        } else {
            summaryTitle = "\(previewItems.count) items"
        }

        let fileCount = previewItems.filter(\.isFileSystemItem).count
        let textCount = previewItems.filter { $0.kind == .text }.count
        let urlCount = previewItems.filter { $0.kind == .url }.count

        var parts: [String] = []
        if fileCount > 0 {
            parts.append(fileCount == 1 ? "1 file" : "\(fileCount) files")
        }
        if textCount > 0 {
            parts.append(textCount == 1 ? "1 text clip" : "\(textCount) text clips")
        }
        if urlCount > 0 {
            parts.append(urlCount == 1 ? "1 URL" : "\(urlCount) URLs")
        }

        summarySubtitle = parts.isEmpty ? "Drop to collect" : parts.joined(separator: " • ")
    }

    static let placeholder = DragPreviewDescriptor(
        itemCount: 0,
        primaryIconNames: [],
        summaryTitle: "New Shelf",
        summarySubtitle: "Drop to collect"
    )
}
