import SwiftUI

/// OcPlayer 风格复制组件 413
struct PXOCUI413: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
            Text("排序").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rose)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rose.opacity(0.12), in: Capsule())
    }
}
