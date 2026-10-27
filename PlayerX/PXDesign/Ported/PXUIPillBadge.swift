import SwiftUI

struct PXUIPillBadge: View {
    let text: String
    var tint: Color = PXTheme.accent

    var body: some View {
        Text(text)
            .font(PXFont.caption(10))
            .foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
    }
}
