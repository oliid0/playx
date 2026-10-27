import SwiftUI

struct PXWGestureHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.caption(10))
            .foregroundStyle(PXTheme.textPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
