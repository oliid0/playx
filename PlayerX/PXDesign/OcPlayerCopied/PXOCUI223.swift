import SwiftUI

/// OcPlayer 风格复制组件 223
struct PXOCUI223: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
            Text("前进").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
