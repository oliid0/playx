import SwiftUI

/// OcPlayer 风格复制组件 147
struct PXOCUI147: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles.tv").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.mint)
            Text("分类").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
