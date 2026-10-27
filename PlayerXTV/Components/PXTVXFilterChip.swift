import SwiftUI

struct PXTVXFilterChip: View {
    let title: String
    let selected: Bool
    var body: some View {
        Text(title)
            .font(PXFont.caption(11))
            .foregroundStyle(selected ? PXTheme.background : PXTheme.textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(selected ? PXTheme.textPrimary : PXTheme.surfaceMuted, in: Capsule())
    }
}
