import SwiftUI
struct PXPlayerProgressLabel: View {
    var current: Double
    var duration: Double
    var body: some View {
        HStack(spacing: 4) {
            Text(PXFormat.time(current)).font(PXFont.mono(10)).foregroundStyle(.white.opacity(0.82))
            Text("/").foregroundStyle(.white.opacity(0.24))
            Text(PXFormat.time(duration)).font(PXFont.mono(10)).foregroundStyle(.white.opacity(0.48))
        }
    }
}
