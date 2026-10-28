import SwiftUI

/// OcPlayer 风格复制组件 345
struct PXOCUI345: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.accent).frame(width: 6, height: 6)
            Text("演员").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
