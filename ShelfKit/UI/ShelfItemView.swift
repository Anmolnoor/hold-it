import SwiftUI

struct ShelfItemView: View {
    let item: ShelfItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconSystemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.white.opacity(0.16) : Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.78) : Color.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor : Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.06), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.06), radius: 14, y: 4)
    }
}
