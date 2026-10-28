import SwiftUI

/// OcPlayer 风格复制组件 188
struct PXOCUI188: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "forward.fill").font(.system(size: 11, weight: .semibold))
            Text("播放全部").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.sky)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.sky.opacity(0.12), in: Capsule())
    }
}
