import SwiftUI

struct PXUIStepIndicator: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule()
                    .fill(index == current ? PXTheme.textPrimary : PXTheme.strokeStrong)
                    .frame(width: index == current ? 18 : 5, height: 4)
            }
        }
        .animation(PXTheme.quick, value: current)
    }
}
