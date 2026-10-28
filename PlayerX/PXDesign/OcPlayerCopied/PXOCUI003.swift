import SwiftUI

/// OcPlayer 风格复制组件 003
struct PXOCUI003: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "forward.end.fill").font(.system(size: 11, weight: .semibold))
            Text("最近添加").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.mint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.mint.opacity(0.12), in: Capsule())
    }
}
