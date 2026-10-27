import SwiftUI

struct PXUIStatusCapsule: View {
    let text: String
    var tint: Color = PXTheme.mint
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(tint).frame(width: 5, height: 5)
            Text(text).font(PXFont.caption(9)).foregroundStyle(PXTheme.textSecondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
