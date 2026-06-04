import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var store: ClipboardHistoryStore
    @ObservedObject var preferences: PreferencesStore

    let onSelect: (ClipboardHistoryItem) -> Void
    let onNewShelf: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            historyList

            Divider()

            footer
        }
        .frame(width: 360, height: 460)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard History")
                    .font(.headline)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.clear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear Clipboard History")
            .disabled(store.items.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var headerSubtitle: String {
        if preferences.clipboardHistoryEnabled == false {
            return "Paused"
        }

        let count = store.items.count
        return count == 1 ? "1 saved item" : "\(count) saved items"
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if store.items.isEmpty {
                    emptyState
                } else {
                    ForEach(store.items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            ClipboardHistoryRow(item: item, image: store.image(for: item))
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: preferences.clipboardHistoryEnabled ? "clipboard" : "pause.circle")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text(preferences.clipboardHistoryEnabled ? "No saved items yet" : "Clipboard History is paused")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: onNewShelf) {
                Label("New Shelf", systemImage: "plus")
            }

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
            }
            .help("Settings")

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .help("Quit HoldIt")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct ClipboardHistoryRow: View {
    let item: ClipboardHistoryItem
    let image: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.displaySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(item.createdAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var icon: some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Image(systemName: item.iconSystemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
