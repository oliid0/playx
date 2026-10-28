import SwiftUI

/// OcPlayer 风格复制组件 185
struct PXOCUI185: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.accent).frame(width: 6, height: 6)
            Text("警告").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
