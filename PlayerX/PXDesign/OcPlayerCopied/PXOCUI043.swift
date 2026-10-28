import SwiftUI

/// OcPlayer 风格复制组件 043
struct PXOCUI043: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "bolt.fill").font(.system(size: 11, weight: .semibold))
            Text("网络").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.mint)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.mint.opacity(0.12), in: Capsule())
    }
}
