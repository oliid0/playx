import SwiftUI

/// OcPlayer 风格复制组件 160
struct PXOCUI160: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textTertiary).frame(width: 6, height: 6)
            Text("前进").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "checkmark").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
