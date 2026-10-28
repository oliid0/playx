import SwiftUI

/// OcPlayer 风格复制组件 145
struct PXOCUI145: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.accent).frame(width: 6, height: 6)
            Text("搜索").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "calendar").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
