import SwiftUI

struct PXTVXBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.caption(9))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
