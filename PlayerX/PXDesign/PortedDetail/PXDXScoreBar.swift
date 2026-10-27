import SwiftUI

struct PXDXScoreBar: View {
    let score: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(PXTheme.stroke)
                Capsule().fill(PXTheme.rating).frame(width: proxy.size.width * min(max(score / 10, 0), 1))
            }
        }
        .frame(height: 4)
    }
}
