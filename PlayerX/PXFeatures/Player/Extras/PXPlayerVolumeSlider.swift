import SwiftUI
struct PXPlayerVolumeSlider: View {
    @Binding var volume: Double
    var onMute: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onMute) { Image(systemName: volume < 0.01 ? "speaker.slash.fill" : "speaker.wave.2.fill") }
                .buttonStyle(.plain)
            Slider(value: $volume, in: 0...1).frame(width: 110)
        }
        .font(.system(size: 11))
        .foregroundStyle(.white.opacity(0.82))
    }
}
