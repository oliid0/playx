import SwiftUI

/// OcPlayer 风格复制组件 165
struct PXOCUI165: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rose).frame(width: 6, height: 6)
            Text("移除").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "square.and.arrow.up").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
