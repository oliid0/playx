import SwiftUI

struct PXWSeekBar: View {
    let current: Double
    let duration: Double
    let buffered: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(PXTheme.stroke).frame(height: 3)
                Capsule().fill(PXTheme.textTertiary).frame(width: proxy.size.width * ratio(buffered), height: 3)
                Capsule().fill(PXTheme.textPrimary).frame(width: proxy.size.width * ratio(current), height: 3)
                Circle().fill(PXTheme.textPrimary).frame(width: 9, height: 9)
                    .offset(x: max(0, proxy.size.width * ratio(current) - 4.5))
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 10)
    }
    private func ratio(_ value: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(value / duration, 0), 1)
    }
}
