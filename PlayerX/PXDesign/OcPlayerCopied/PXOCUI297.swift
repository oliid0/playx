import SwiftUI

/// OcPlayer 风格复制组件 297
struct PXOCUI297: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sun.max.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.accent)
            Text("加速").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
