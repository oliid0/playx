import SwiftUI

/// OcPlayer 风格复制组件 028
struct PXOCUI028: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.open").font(.system(size: 11, weight: .semibold))
            Text("电影").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.sky)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.sky.opacity(0.12), in: Capsule())
    }
}
