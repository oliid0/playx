import SwiftUI

/// OcPlayer 风格复制组件 163
struct PXOCUI163: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "minus").font(.system(size: 11, weight: .semibold))
            Text("关闭").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.mint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.mint.opacity(0.12), in: Capsule())
    }
}
