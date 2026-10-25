import SwiftUI

struct PXHeroCard: View {
    var item: PXHeroItem
    var height: CGFloat = PXTheme.heroHeight

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PXRemoteImage(url: item.backdropURL ?? URL(string: item.entry.drama.cover ?? ""), maxPixel: 2000)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.06), location: 0),
                    .init(color: .black.opacity(0.24), location: 0.42),
                    .init(color: PXTheme.background.opacity(0.90), location: 0.78),
                    .init(color: PXTheme.background, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [PXTheme.background.opacity(0.78), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )

            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    PXTag(text: item.entry.kind.title, tint: PXTheme.accent)
                    if item.entry.providerID == "hongguo" { PXTag(text: "独家", tint: PXTheme.rose) }
                    if let rating = item.rating { PXRatingBadge(rating: rating) }
                }
                if let logo = item.logoURL {
                    PXRemoteImage(url: logo, contentMode: .fit, maxPixel: 900)
                        .frame(maxWidth: 360, maxHeight: 100, alignment: .leading)
                } else {
                    Text(item.title)
                        .font(PXFont.display(40))
                        .foregroundStyle(PXTheme.textPrimary)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.42), radius: 12, y: 5)
                }
                PXMetadataLine(parts: [item.subtitle] + item.genres.prefix(3))
                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(PXTheme.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(3)
                        .frame(maxWidth: 560, alignment: .leading)
                }
                HStack(spacing: 10) {
                    Label("播放", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black.opacity(0.86))
                        .padding(.horizontal, 20)
                        .frame(height: 42)
                        .background(PXTheme.accentGradient, in: Capsule())
                    Label("详情", systemImage: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PXTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                        .background(PXTheme.surfaceStrong, in: Capsule())
                        .overlay(Capsule().strokeBorder(PXTheme.strokeStrong, lineWidth: 0.8))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, PXTheme.widePadding)
            .padding(.bottom, 28)
            .frame(maxWidth: 820, alignment: .leading)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(PXTheme.stroke, lineWidth: 0.8)
        }
    }
}
