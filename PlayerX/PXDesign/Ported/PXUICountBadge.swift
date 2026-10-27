import SwiftUI

struct PXUICountBadge: View {
    let count: Int
    var tint: Color = PXTheme.textSecondary
    var body: some View {
        Text("\(count)")
            .font(PXFont.mono(10)).foregroundStyle(tint)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
