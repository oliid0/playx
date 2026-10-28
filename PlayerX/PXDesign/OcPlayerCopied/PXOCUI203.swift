import SwiftUI

/// OcPlayer 风格复制组件 203
struct PXOCUI203: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "ellipsis").font(.system(size: 11, weight: .semibold))
            Text("信息").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.mint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.mint.opacity(0.12), in: Capsule())
    }
}
