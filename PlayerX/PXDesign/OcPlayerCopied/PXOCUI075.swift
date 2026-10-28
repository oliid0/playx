import SwiftUI

/// OcPlayer 风格复制组件 075
struct PXOCUI075: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.mint).frame(width: 6, height: 6)
            Text("选集").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
