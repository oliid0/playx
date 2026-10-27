import SwiftUI

struct PXUIProgressRing: View {
    let progress: Double
    var size: CGFloat = 42
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle().stroke(PXTheme.stroke, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(PXTheme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(min(max(progress, 0), 1) * 100))%")
                .font(PXFont.mono(9)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(width: size, height: size)
    }
}
