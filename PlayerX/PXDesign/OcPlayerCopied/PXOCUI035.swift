import SwiftUI

/// OcPlayer 风格复制组件 035
struct PXOCUI035: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.mint).frame(width: 6, height: 6)
            Text("排序").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
