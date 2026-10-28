import SwiftUI

/// OcPlayer 风格复制组件 393
struct PXOCUI393: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass").font(.system(size: 11, weight: .semibold))
            Text("收藏").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
