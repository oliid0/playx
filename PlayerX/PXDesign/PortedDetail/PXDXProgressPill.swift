import SwiftUI

struct PXDXProgressPill: View {
    let progress: Double
    var body: some View {
        HStack(spacing: 6) {
            PXProgressBar(value: progress, height: 3).frame(width: 64)
            Text(PXFormat.percent(progress)).font(PXFont.mono(9)).foregroundStyle(PXTheme.textTertiary)
        }
    }
}
