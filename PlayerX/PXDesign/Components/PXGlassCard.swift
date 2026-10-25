import SwiftUI

struct PXGlassCardModifier: ViewModifier {
    var radius: CGFloat = PXTheme.cardRadius
    var padding: CGFloat? = nil
    var stroke: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding ?? 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(PXTheme.panelGradient)
            )
            .overlay {
                if stroke {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(PXTheme.stroke, lineWidth: 0.8)
                }
            }
    }
}

extension View {
    func pxGlassCard(radius: CGFloat = PXTheme.cardRadius, padding: CGFloat? = 16) -> some View {
        modifier(PXGlassCardModifier(radius: radius, padding: padding))
    }

    func pxFlatCard(radius: CGFloat = PXTheme.cardRadius, padding: CGFloat? = 16) -> some View {
        self
            .padding(padding ?? 16)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(PXTheme.stroke, lineWidth: 0.7)
            }
    }

    func pxSectionHeaderPadding() -> some View {
        padding(.horizontal, PXTheme.contentPadding)
    }
}
