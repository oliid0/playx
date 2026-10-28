import SwiftUI

/// OcPlayer 风格复制组件 175
struct PXOCUI175: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rating).frame(width: 6, height: 6)
            Text("全屏").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "text.alignleft").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
