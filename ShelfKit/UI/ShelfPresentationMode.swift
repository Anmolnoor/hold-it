import Foundation

enum ShelfPresentationMode: Equatable {
    case preview(DragPreviewDescriptor)
    case notchPreview(DragPreviewDescriptor?)
    case expanded
    case notchExpanded

    var isPreview: Bool {
        switch self {
        case .preview, .notchPreview:
            return true
        case .expanded, .notchExpanded:
            return false
        }
    }

    var isNotchPresentation: Bool {
        switch self {
        case .notchPreview, .notchExpanded:
            return true
        case .preview, .expanded:
            return false
        }
    }

    var previewDescriptor: DragPreviewDescriptor? {
        switch self {
        case let .preview(descriptor):
            return descriptor
        case let .notchPreview(descriptor):
            return descriptor
        case .expanded, .notchExpanded:
            return nil
        }
    }
}
