import SwiftUI

struct PXWProgressDots: View {
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(count, 1), id: \.self) { index in
                Capsule().fill(index == current ? PXTheme.textPrimary : PXTheme.strokeStrong)
                    .frame(width: index == current ? 12 : 4, height: 3)
            }
        }
    }
}
