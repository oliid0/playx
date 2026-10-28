import SwiftUI

/// OcPlayer 风格复制组件 343
struct PXOCUI343: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.open").font(.system(size: 11, weight: .semibold))
            Text("电影").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
