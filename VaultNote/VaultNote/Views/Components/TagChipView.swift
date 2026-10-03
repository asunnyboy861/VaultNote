import SwiftUI

struct TagChipView: View {
    let tag: String
    var color: Color? = nil
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                if let color = color {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }

                Text("#\(tag)")
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? (color ?? Color.accentColor) : Color.accentColor.opacity(0.12))
            .foregroundStyle(isSelected ? .white : (color ?? Color.accentColor))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
