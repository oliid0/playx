import SwiftUI

/// OcPlayer 风格复制组件 247
struct PXOCUI247: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rating)
            Text("帮助").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
