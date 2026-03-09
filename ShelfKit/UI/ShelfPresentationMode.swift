import Foundation

enum ShelfPresentationMode: Equatable {
    case preview(DragPreviewDescriptor)
    case expanded

    var isPreview: Bool {
        if case .preview = self {
            return true
        }

        return false
    }

    var previewDescriptor: DragPreviewDescriptor? {
        if case let .preview(descriptor) = self {
            return descriptor
        }

        return nil
    }
}
