import SwiftUI

/// OcPlayer 风格复制组件 437
struct PXOCUI437: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rose)
            Text("警告").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
