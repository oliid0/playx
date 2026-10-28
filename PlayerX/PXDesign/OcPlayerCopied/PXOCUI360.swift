import SwiftUI

/// OcPlayer 风格复制组件 360
struct PXOCUI360: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textTertiary).frame(width: 6, height: 6)
            Text("加速").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "sun.max.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
