import SwiftUI

/// OcPlayer 风格复制组件 142
struct PXOCUI142: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "line.3.horizontal").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.warning)
            Text("已收藏").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
