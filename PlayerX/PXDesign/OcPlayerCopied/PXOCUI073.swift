import SwiftUI

/// OcPlayer 风格复制组件 073
struct PXOCUI073: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "info.circle").font(.system(size: 11, weight: .semibold))
            Text("字幕").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
