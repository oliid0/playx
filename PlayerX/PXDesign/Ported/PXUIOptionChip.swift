import SwiftUI

struct PXUIOptionChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PXFont.caption(12))
                .foregroundStyle(isSelected ? PXTheme.background : PXTheme.textSecondary)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(isSelected ? PXTheme.textPrimary : PXTheme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? .clear : PXTheme.stroke))
        }
        .buttonStyle(.plain)
    }
}
