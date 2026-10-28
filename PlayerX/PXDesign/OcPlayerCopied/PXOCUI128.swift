import SwiftUI

/// OcPlayer 风格复制组件 128
struct PXOCUI128: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "pause.fill").font(.system(size: 11, weight: .semibold))
            Text("接下来看").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textTertiary.opacity(0.12), in: Capsule())
    }
}
