import SwiftUI

struct PXDXEpisodeList: View {
    let episodes: [PXEpisodeInfo]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(episodes) { episode in
                HStack(spacing: 10) {
                    Text(episode.episodeLabel).font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary).frame(width: 52, alignment: .leading)
                    Text(episode.displayName).font(PXFont.body(12)).lineLimit(1)
                    Spacer()
                    if let runtime = episode.runtimeMinutes { Text("\(runtime) 分").font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary) }
                }
                .padding(.vertical, 8)
                if episode.id != episodes.last?.id { PXUIGradientDivider() }
            }
        }
    }
}
