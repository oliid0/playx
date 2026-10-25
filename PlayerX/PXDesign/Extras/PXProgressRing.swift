import SwiftUI
struct PXProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 5
    var tint: Color = PXTheme.accent
    var body: some View {
        ZStack {
            Circle().stroke(PXTheme.stroke, lineWidth: lineWidth)
            Circle().trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(PXTheme.standard, value: progress)
    }
}
