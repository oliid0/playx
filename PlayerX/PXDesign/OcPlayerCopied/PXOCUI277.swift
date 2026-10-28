import SwiftUI

/// OcPlayer 风格复制组件 277
struct PXOCUI277: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "tv").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rose)
            Text("元数据").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
