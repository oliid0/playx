import SwiftUI

struct PXDXEpisodeRow: View {
    let episode: PXEpisodeInfo
    let progress: Double
    var body: some View {
        HStack(spacing: 10) {
            PXRemoteImage(url: episode.stillURL, maxPixel: 300)
                .frame(width: 82, height: 46).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 3) {
                Text(episode.displayName).font(PXFont.body(11)).lineLimit(1)
                Text(episode.episodeLabel).font(PXFont.mono(9)).foregroundStyle(PXTheme.textTertiary)
                if progress > 0 { PXProgressBar(value: progress, height: 2) }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
