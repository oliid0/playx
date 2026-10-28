import SwiftUI

/// OcPlayer 风格复制组件 430
struct PXOCUI430: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.warning).frame(width: 6, height: 6)
            Text("刷新").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "eye").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
