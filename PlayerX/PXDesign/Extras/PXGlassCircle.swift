import SwiftUI

struct PXGlassCircle<Content: View>: View {
    var size: CGFloat = 40
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(PXTheme.stroke, lineWidth: 0.8))
    }
}
