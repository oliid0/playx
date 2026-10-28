import SwiftUI

/// OcPlayer 风格复制组件 098
struct PXOCUI098: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
            Text("排序").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textSecondary.opacity(0.12), in: Capsule())
    }
}
