import SwiftUI

/// OcPlayer 风格复制组件 102
struct PXOCUI102: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.and.arrow.up").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.warning)
            Text("移除").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
