import SwiftUI

/// OcPlayer 风格复制组件 278
struct PXOCUI278: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "person.2.fill").font(.system(size: 11, weight: .semibold))
            Text("评分").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.warning)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.warning.opacity(0.12), in: Capsule())
    }
}
