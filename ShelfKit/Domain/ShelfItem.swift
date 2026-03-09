import Foundation

enum ShelfItemType: String, Codable {
    case file
    case folder
    case text
    case url
}

enum ShelfItemSourceKind: String, Codable {
    case fileReference
    case plainText
    case webURL
}

struct ShelfItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ShelfItemType
    let sourceKind: ShelfItemSourceKind
    var displayName: String
    var originalURL: URL?
    var bookmarkData: Data?
    var localStoredURL: URL?
    var thumbnailKey: String?
    var textValue: String?
    var metadata: [String: String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: ShelfItemType,
        sourceKind: ShelfItemSourceKind,
        displayName: String,
        originalURL: URL? = nil,
        bookmarkData: Data? = nil,
        localStoredURL: URL? = nil,
        thumbnailKey: String? = nil,
        textValue: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.sourceKind = sourceKind
        self.displayName = displayName
        self.originalURL = originalURL
        self.bookmarkData = bookmarkData
        self.localStoredURL = localStoredURL
        self.thumbnailKey = thumbnailKey
        self.textValue = textValue
        self.metadata = metadata
        self.createdAt = createdAt
    }

    init(fileURL: URL, isDirectory: Bool) {
        let name = fileURL.lastPathComponent.isEmpty ? fileURL.path : fileURL.lastPathComponent

        self.init(
            type: isDirectory ? .folder : .file,
            sourceKind: .fileReference,
            displayName: name,
            originalURL: fileURL
        )
    }

    init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = String(trimmed.prefix(80))

        self.init(
            type: .text,
            sourceKind: .plainText,
            displayName: preview.isEmpty ? "Text Clip" : preview,
            textValue: trimmed
        )
    }

    init(url: URL) {
        self.init(
            type: .url,
            sourceKind: .webURL,
            displayName: url.host ?? url.absoluteString,
            originalURL: url
        )
    }

    var iconSystemName: String {
        switch type {
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

    var subtitle: String {
        switch type {
        case .file, .folder:
            return originalURL?.path ?? "Local reference"
        case .text:
            return "Plain text"
        case .url:
            return originalURL?.absoluteString ?? displayName
        }
    }

    var isFileSystemItem: Bool {
        type == .file || type == .folder
    }
}
