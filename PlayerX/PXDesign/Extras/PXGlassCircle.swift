import SwiftUI
struct PXGlassCircle: View {
    var size: CGFloat = 40
    @ViewBuilder var content: () -> AnyView
    var body: some View {
        content()
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(PXTheme.stroke, lineWidth: 0.8))
    }
}
