import SwiftUI

/// OcPlayer 风格复制组件 008
struct PXOCUI008: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "rectangle.stack").font(.system(size: 11, weight: .semibold))
            Text("上一集").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textTertiary.opacity(0.12), in: Capsule())
    }
}
