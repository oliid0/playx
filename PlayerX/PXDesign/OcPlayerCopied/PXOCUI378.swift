import SwiftUI

/// OcPlayer 风格复制组件 378
struct PXOCUI378: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "backward.fill").font(.system(size: 11, weight: .semibold))
            Text("继续播放").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textSecondary.opacity(0.12), in: Capsule())
    }
}
