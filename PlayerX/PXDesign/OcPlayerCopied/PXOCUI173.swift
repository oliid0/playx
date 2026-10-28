import SwiftUI

/// OcPlayer 风格复制组件 173
struct PXOCUI173: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "rectangle.on.rectangle").font(.system(size: 11, weight: .semibold))
            Text("亮度").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rose)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rose.opacity(0.12), in: Capsule())
    }
}
