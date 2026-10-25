import SwiftUI
struct PXLoadingSpinner: View {
    var size: CGFloat = 24
    @State private var spin = false
    var body: some View {
        Circle().trim(from: 0.08, to: 0.92)
            .stroke(PXTheme.accent, style: StrokeStyle(lineWidth: max(2, size * 0.09), lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(spin ? 360 : 0))
            .onAppear { withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { spin = true } }
    }
}
