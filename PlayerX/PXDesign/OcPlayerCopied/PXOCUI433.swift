import SwiftUI

/// OcPlayer 风格复制组件 433
struct PXOCUI433: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "bell.slash").font(.system(size: 11, weight: .semibold))
            Text("隐藏").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
