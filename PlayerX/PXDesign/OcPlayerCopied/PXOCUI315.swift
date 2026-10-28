import SwiftUI

/// OcPlayer 风格复制组件 315
struct PXOCUI315: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.mint).frame(width: 6, height: 6)
            Text("继续播放").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "backward.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
