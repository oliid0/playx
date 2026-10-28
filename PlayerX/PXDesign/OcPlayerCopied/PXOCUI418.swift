import SwiftUI

/// OcPlayer 风格复制组件 418
struct PXOCUI418: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "link").font(.system(size: 11, weight: .semibold))
            Text("删除").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textSecondary.opacity(0.12), in: Capsule())
    }
}
