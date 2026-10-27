import SwiftUI

struct PXUIScoreRing: View {
    let score: Double
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            Circle().stroke(PXTheme.stroke, lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(score / 10, 0), 1))
                .stroke(PXTheme.rating, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.1f", score))
                .font(PXFont.mono(13)).foregroundStyle(PXTheme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}
