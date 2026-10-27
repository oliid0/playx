import SwiftUI

struct PXWVolumeBar: View {
    @Binding var volume: Double
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: volume < 0.01 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 10)).foregroundStyle(PXTheme.textSecondary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PXTheme.stroke)
                    Capsule().fill(PXTheme.textPrimary).frame(width: proxy.size.width * volume)
                }
            }
            .frame(width: 70, height: 3)
        }
    }
}
