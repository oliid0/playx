import SwiftUI

/// OcPlayer 风格复制组件 191
struct PXOCUI191: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pause.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.rating)
            Text("接下来看").font(PXFont.caption(11)).foregroundStyle(PXTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
