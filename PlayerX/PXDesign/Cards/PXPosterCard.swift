import SwiftUI

struct PXPosterCard: View {
    var entry: PXCatalogEntry
    var width: CGFloat = PXTheme.posterWidth
    var showTitle: Bool = true
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .bottomLeading) {
                PXCoverImage(drama: entry.drama, maxPixel: width * 3)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .frame(width: width)
                    .clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous)
                            .strokeBorder(PXTheme.stroke, lineWidth: 0.6)
                    }
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous))

                HStack(spacing: 4) {
                    if entry.drama.vip == true {
                        PXTag(text: "VIP", tint: PXTheme.accent)
                    }
                    if let count = entry.drama.pxEpisodeCount, entry.kind.isEpisodic {
                        PXTag(text: "\(count) 集", tint: .white.opacity(0.82))
                    }
                }
                .padding(8)

                if let progress, progress > 0 {
                    PXProgressBar(value: progress, height: 3)
                        .padding(.horizontal, 7)
                        .padding(.bottom, 6)
                }
            }
            .frame(width: width)

            if showTitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.drama.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PXTheme.textPrimary)
                        .lineLimit(1)
                    Text(entry.drama.pxDisplaySubtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(1)
                }
                .frame(width: width, alignment: .leading)
            }
        }
        .frame(width: width, alignment: .leading)
        .pxHoverLift()
    }
}
