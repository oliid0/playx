import SwiftUI

/// OcPlayer 风格复制组件 055
struct PXOCUI055: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rating).frame(width: 6, height: 6)
            Text("隐藏").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "bell.slash").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
