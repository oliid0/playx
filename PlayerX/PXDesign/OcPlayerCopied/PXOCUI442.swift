import SwiftUI

/// OcPlayer 风格复制组件 442
struct PXOCUI442: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "play.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text("继续观看").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
