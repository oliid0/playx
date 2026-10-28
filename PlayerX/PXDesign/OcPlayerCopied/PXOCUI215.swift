import SwiftUI

/// OcPlayer 风格复制组件 215
struct PXOCUI215: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rating).frame(width: 6, height: 6)
            Text("评分").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "person.2.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
