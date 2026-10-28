import SwiftUI

/// OcPlayer 风格复制组件 372
struct PXOCUI372: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.sky)
            Text("静音").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
