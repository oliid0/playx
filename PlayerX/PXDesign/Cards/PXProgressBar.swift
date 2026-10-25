import SwiftUI

struct PXProgressBar: View {
    var value: Double
    var height: CGFloat = 3
    var tint: Color = PXTheme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .accessibilityValue(PXFormat.percent(value))
    }
}
