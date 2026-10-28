import SwiftUI

/// OcPlayer 风格复制组件 180
struct PXOCUI180: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.sky).frame(width: 6, height: 6)
            Text("显示").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "bell").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
