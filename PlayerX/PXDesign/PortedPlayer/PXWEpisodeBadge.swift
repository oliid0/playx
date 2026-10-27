import SwiftUI

struct PXWEpisodeBadge: View {
    let index: Int
    let total: Int
    var body: some View {
        Text("\(index + 1)/\(total)")
            .font(PXFont.mono(9))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
