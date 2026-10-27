import SwiftUI

/// OcPlayer 玻璃面板的 PlayerX 版本：细描边 + 半透明材质 + 大圆角。
struct PXUIGlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = PXTheme.panelRadius
    var padding: CGFloat = 18
    let content: Content

    init(cornerRadius: CGFloat = PXTheme.panelRadius, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(PXTheme.panelGradient))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(PXTheme.stroke, lineWidth: 0.8))
    }
}
