import SwiftUI

/// OcPlayer 风格复制组件 120
struct PXOCUI120: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textTertiary).frame(width: 6, height: 6)
            Text("静音").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "exclamationmark.triangle").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
