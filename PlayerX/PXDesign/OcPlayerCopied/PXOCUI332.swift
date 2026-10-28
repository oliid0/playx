import SwiftUI

/// OcPlayer 风格复制组件 332
struct PXOCUI332: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.sky)
            Text("下载").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
