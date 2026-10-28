import SwiftUI

/// OcPlayer 风格复制组件 265
struct PXOCUI265: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.accent).frame(width: 6, height: 6)
            Text("设置").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "arrow.down.circle").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
