import SwiftUI

/// OcPlayer 风格复制组件 140
struct PXOCUI140: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.sky).frame(width: 6, height: 6)
            Text("信息").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "ellipsis").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
