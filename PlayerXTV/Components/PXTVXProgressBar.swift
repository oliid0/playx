import SwiftUI

struct PXTVXProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(PXTheme.stroke)
                .overlay(alignment: .leading) {
                    Capsule().fill(PXTheme.accent).frame(width: proxy.size.width * min(max(value, 0), 1))
                }
        }
        .frame(height: 3)
    }
}
