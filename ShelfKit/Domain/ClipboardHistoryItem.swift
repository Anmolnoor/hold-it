import Foundation

enum ClipboardHistoryItemKind: String, Codable {
    case text
    case url
    case file
    case folder
    case image
    case mixed
}

struct ClipboardHistoryImageInfo: Codable, Hashable {
    var filename: String
    var width: Double
    var height: Double
}

struct ClipboardHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: ClipboardHistoryItemKind
    var displayTitle: String
    var displaySubtitle: String
    var textValue: String?
    var url: URL?
    var fileURLs: [URL]
    var imageInfo: ClipboardHistoryImageInfo?
    var signature: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: ClipboardHistoryItemKind,
        displayTitle: String,
        displaySubtitle: String,
        textValue: String? = nil,
        url: URL? = nil,
        fileURLs: [URL] = [],
        imageInfo: ClipboardHistoryImageInfo? = nil,
        signature: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.displayTitle = displayTitle
        self.displaySubtitle = displaySubtitle
        self.textValue = textValue
        self.url = url
        self.fileURLs = fileURLs
        self.imageInfo = imageInfo
        self.signature = signature
        self.createdAt = createdAt
    }

    var iconSystemName: String {
        switch kind {
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        case .file:
            return "doc"
        case .folder:
            return "folder"
        case .image:
            return "photo"
        case .mixed:
            return "square.stack.3d.up.fill"
        }
    }
}
