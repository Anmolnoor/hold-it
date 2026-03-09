import Foundation

enum ShelfDockEdge: String, Codable {
    case left
    case right
    case top
    case bottom
}

struct Shelf: Identifiable, Codable {
    let id: UUID
    var name: String
    var colorTag: String?
    let createdAt: Date
    var updatedAt: Date
    var pinned: Bool
    var dockedEdge: ShelfDockEdge?
    var items: [ShelfItem]

    init(
        id: UUID = UUID(),
        name: String = "New Shelf",
        colorTag: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pinned: Bool = false,
        dockedEdge: ShelfDockEdge? = nil,
        items: [ShelfItem] = []
    ) {
        self.id = id
        self.name = name
        self.colorTag = colorTag
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pinned = pinned
        self.dockedEdge = dockedEdge
        self.items = items
    }

    mutating func append(items newItems: [ShelfItem]) {
        guard newItems.isEmpty == false else {
            return
        }

        items.append(contentsOf: newItems)
        updatedAt = Date()
    }

    mutating func removeItems(ids: Set<ShelfItem.ID>) {
        guard ids.isEmpty == false else {
            return
        }

        items.removeAll { ids.contains($0.id) }
        updatedAt = Date()
    }
}
