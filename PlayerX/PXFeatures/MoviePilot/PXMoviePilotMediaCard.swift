import SwiftUI

struct PXMoviePilotMediaCard: View {
    let media: PXMoviePilotMedia

    var body: some View {
        HStack(spacing: 12) {
            PXRemoteImage(url: media.posterURL, maxPixel: 300)
                .frame(width: 58, height: 87)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PXTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let year = media.year { PXTag(text: year) }
                    if let type = media.type { PXTag(text: type, tint: PXTheme.sky) }
                    if let season = media.season { PXTag(text: "第 \(season) 季", tint: PXTheme.mint) }
                }
                if let overview = media.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: 10))
                        .foregroundStyle(PXTheme.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PXTheme.textTertiary)
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
