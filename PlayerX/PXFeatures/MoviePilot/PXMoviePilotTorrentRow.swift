import SwiftUI

struct PXMoviePilotTorrentRow: View {
    let torrent: PXMoviePilotTorrent
    let onDownload: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PXTheme.accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(torrent.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    if let site = torrent.siteName { PXTag(text: site, tint: PXTheme.sky) }
                    if let size = torrent.sizeText { PXTag(text: size) }
                    if let seeders = torrent.seeders {
                        Text("↑\(seeders)").font(.system(size: 9, weight: .bold)).foregroundStyle(PXTheme.mint)
                    }
                    if let peers = torrent.peers {
                        Text("↓\(peers)").font(.system(size: 9, weight: .bold)).foregroundStyle(PXTheme.textTertiary)
                    }
                }
                if let description = torrent.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 9))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button("下载", action: onDownload)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.black.opacity(0.84))
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(PXTheme.accent, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
