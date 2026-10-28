import SwiftUI

/// OcPlayer 风格复制组件 096
struct PXOCUI096: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            Text("返回").font(PXFont.caption(11)).foregroundStyle(PXTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
