import SwiftUI

/// OcPlayer 风格复制组件 153
struct PXOCUI153: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill").font(.system(size: 11, weight: .semibold))
            Text("时长").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.accent)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
