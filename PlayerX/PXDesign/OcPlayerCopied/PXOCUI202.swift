import SwiftUI

/// OcPlayer 风格复制组件 202
struct PXOCUI202: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.down.circle").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text("设置").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
