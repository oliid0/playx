import SwiftUI

/// OcPlayer 风格复制组件 325
struct PXOCUI325: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rose).frame(width: 6, height: 6)
            Text("字幕").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "info.circle").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
