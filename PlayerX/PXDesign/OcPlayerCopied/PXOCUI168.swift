import SwiftUI

/// OcPlayer 风格复制组件 168
struct PXOCUI168: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "wifi").font(.system(size: 11, weight: .semibold))
            Text("链接").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textTertiary.opacity(0.12), in: Capsule())
    }
}
