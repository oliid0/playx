import SwiftUI

struct PXUIHoverScale: ViewModifier {
    @State private var hovering = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(hovering ? 1.02 : 1)
            .animation(PXTheme.quick, value: hovering)
            #if os(macOS)
            .onHover { hovering = $0 }
            #endif
    }
}

extension View {
    func pxHoverScale() -> some View { modifier(PXUIHoverScale()) }
}
