import SwiftUI

/// OcPlayer 风格复制组件 152
struct PXOCUI152: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.2.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            Text("评分").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
