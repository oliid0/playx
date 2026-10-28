import SwiftUI

/// OcPlayer 风格复制组件 038
struct PXOCUI038: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "trash").font(.system(size: 11, weight: .semibold))
            Text("添加").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.warning)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.warning.opacity(0.12), in: Capsule())
    }
}
