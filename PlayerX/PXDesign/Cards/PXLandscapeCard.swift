import SwiftUI

struct PXLandscapeCard: View {
    var entry: PXCatalogEntry
    var width: CGFloat = PXTheme.landscapeWidth
    var showTitle: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                PXCoverImage(drama: entry.drama, maxPixel: width * 2.4)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(width: width, height: width * 9 / 16)
                    .clipped()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.70)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                HStack(spacing: 5) {
                    PXTag(text: entry.kind.title, tint: PXTheme.accentSoft)
                    if let year = entry.drama.pxYear {
                        Text(String(year))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(10)
            }
            .frame(width: width, height: width * 9 / 16)
            .clipShape(RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PXTheme.posterRadius, style: .continuous)
                    .strokeBorder(PXTheme.stroke, lineWidth: 0.6)
            }

            if showTitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.drama.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PXTheme.textPrimary)
                        .lineLimit(1)
                    Text(entry.drama.description?.isEmpty == false ? entry.drama.description! : entry.drama.pxDisplaySubtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(2)
                }
                .frame(width: width, alignment: .leading)
            }
        }
        .frame(width: width, alignment: .leading)
        .pxHoverLift()
    }
}
