import SwiftUI

/// OcPlayer 风格复制组件 016
struct PXOCUI016: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal").font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textTertiary)
            Text("已收藏").font(PXFont.caption(11)).foregroundStyle(PXTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
