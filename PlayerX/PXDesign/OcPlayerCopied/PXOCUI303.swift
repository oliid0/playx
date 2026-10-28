import SwiftUI

/// OcPlayer 风格复制组件 303
struct PXOCUI303: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "arrow.counterclockwise").font(.system(size: 11, weight: .semibold))
            Text("文本").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
