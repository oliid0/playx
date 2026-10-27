import SwiftUI

struct PXWBufferingRing: View {
    @State private var spin = false
    var body: some View {
        Circle()
            .trim(from: 0.08, to: 0.78)
            .stroke(PXTheme.textPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(spin ? 360 : 0))
            .onAppear { withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { spin = true } }
    }
}
