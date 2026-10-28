import SwiftUI

/// OcPlayer 风格复制组件 143
struct PXOCUI143: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "square.grid.2x2").font(.system(size: 11, weight: .semibold))
            Text("下载").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
