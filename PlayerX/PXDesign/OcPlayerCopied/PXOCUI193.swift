import SwiftUI

/// OcPlayer 风格复制组件 193
struct PXOCUI193: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "backward.end.fill").font(.system(size: 11, weight: .semibold))
            Text("媒体库").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
