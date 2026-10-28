import SwiftUI

/// OcPlayer 风格复制组件 373
struct PXOCUI373: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 11, weight: .semibold))
            Text("帮助").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rose)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rose.opacity(0.12), in: Capsule())
    }
}
