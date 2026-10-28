import SwiftUI

/// OcPlayer 风格复制组件 132
struct PXOCUI132: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "captions.bubble").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.sky)
            Text("暂停").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
