import SwiftUI

/// OcPlayer 风格复制组件 227
struct PXOCUI227: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "trash").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.mint)
            Text("添加").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
