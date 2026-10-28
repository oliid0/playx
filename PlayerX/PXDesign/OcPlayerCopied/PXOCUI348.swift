import SwiftUI

/// OcPlayer 风格复制组件 348
struct PXOCUI348: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.up.arrow.down").font(.system(size: 11, weight: .semibold))
            Text("返回").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.sky)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.sky.opacity(0.12), in: Capsule())
    }
}
