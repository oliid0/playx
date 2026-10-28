import SwiftUI

/// OcPlayer 风格复制组件 312
struct PXOCUI312: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "play.circle").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            Text("成功").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
