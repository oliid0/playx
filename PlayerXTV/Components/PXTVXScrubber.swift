import SwiftUI

struct PXTVXScrubber: View {
    let current: Double
    let duration: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(PXTheme.stroke).frame(height: 4)
                Capsule().fill(PXTheme.textPrimary)
                    .frame(width: proxy.size.width * (duration > 0 ? min(max(current / duration, 0), 1) : 0), height: 4)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 10)
    }
}
