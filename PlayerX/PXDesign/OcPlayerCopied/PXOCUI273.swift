import SwiftUI

/// OcPlayer 风格复制组件 273
struct PXOCUI273: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles.tv").font(.system(size: 11, weight: .semibold))
            Text("分类").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
