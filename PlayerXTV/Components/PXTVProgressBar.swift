import SwiftUI
struct PXTVProgressBar: View {
    var value: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule().fill(PXTheme.accent).frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 3)
    }
}
