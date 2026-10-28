import SwiftUI

/// OcPlayer 风格复制组件 155
struct PXOCUI155: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.mint).frame(width: 6, height: 6)
            Text("剧集").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.left").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
