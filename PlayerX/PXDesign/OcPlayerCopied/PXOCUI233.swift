import SwiftUI

/// OcPlayer 风格复制组件 233
struct PXOCUI233: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "moon.zzz.fill").font(.system(size: 11, weight: .semibold))
            Text("连接").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
