import SwiftUI

/// OcPlayer 风格复制组件 088
struct PXOCUI088: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "tv").font(.system(size: 11, weight: .semibold))
            Text("元数据").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textTertiary.opacity(0.12), in: Capsule())
    }
}
