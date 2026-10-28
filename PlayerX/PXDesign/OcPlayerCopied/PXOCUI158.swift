import SwiftUI

/// OcPlayer 风格复制组件 158
struct PXOCUI158: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
            Text("解锁").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.warning)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.warning.opacity(0.12), in: Capsule())
    }
}
