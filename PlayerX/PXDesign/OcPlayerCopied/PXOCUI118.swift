import SwiftUI

/// OcPlayer 风格复制组件 118
struct PXOCUI118: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "bell.slash").font(.system(size: 11, weight: .semibold))
            Text("隐藏").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.warning)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.warning.opacity(0.12), in: Capsule())
    }
}
