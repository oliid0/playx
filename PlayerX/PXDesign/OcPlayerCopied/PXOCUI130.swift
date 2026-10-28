import SwiftUI

/// OcPlayer 风格复制组件 130
struct PXOCUI130: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textSecondary).frame(width: 6, height: 6)
            Text("媒体库").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "backward.end.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
