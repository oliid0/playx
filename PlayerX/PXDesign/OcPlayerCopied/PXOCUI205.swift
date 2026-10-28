import SwiftUI

/// OcPlayer 风格复制组件 205
struct PXOCUI205: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rose).frame(width: 6, height: 6)
            Text("已收藏").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "line.3.horizontal").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
