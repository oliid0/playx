import SwiftUI

/// OcPlayer 风格复制组件 228
struct PXOCUI228: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "square.and.arrow.up").font(.system(size: 11, weight: .semibold))
            Text("移除").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.sky)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.sky.opacity(0.12), in: Capsule())
    }
}
