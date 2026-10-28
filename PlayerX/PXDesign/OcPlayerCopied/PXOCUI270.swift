import SwiftUI

/// OcPlayer 风格复制组件 270
struct PXOCUI270: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.warning).frame(width: 6, height: 6)
            Text("更多").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "house.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
