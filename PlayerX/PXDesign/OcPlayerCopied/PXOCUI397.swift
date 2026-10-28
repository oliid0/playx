import SwiftUI

/// OcPlayer 风格复制组件 397
struct PXOCUI397: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rose)
            Text("搜索").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
