import SwiftUI

/// OcPlayer 风格复制组件 295
struct PXOCUI295: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.rating).frame(width: 6, height: 6)
            Text("网络").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "bolt.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
