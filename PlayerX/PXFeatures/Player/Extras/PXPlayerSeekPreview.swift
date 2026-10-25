import SwiftUI
struct PXPlayerSeekPreview: View {
    var target: Double
    var delta: Double
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: delta >= 0 ? "goforward" : "gobackward").font(.system(size: 11, weight: .bold))
            Text(PXFormat.time(target)).font(PXFont.mono(12))
            Text(String(format: "%+.0f 秒", delta)).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.58))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).frame(height: 38)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
