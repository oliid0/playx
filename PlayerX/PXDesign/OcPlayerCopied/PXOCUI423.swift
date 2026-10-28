import SwiftUI

/// OcPlayer 风格复制组件 423
struct PXOCUI423: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sun.max.fill").font(.system(size: 11, weight: .semibold))
            Text("加速").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
