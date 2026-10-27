import SwiftUI

struct PXWChapterChip: View {
    let title: String
    let selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PXFont.caption(10))
                .foregroundStyle(selected ? PXTheme.background : PXTheme.textSecondary)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(selected ? PXTheme.textPrimary : PXTheme.surfaceMuted, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
