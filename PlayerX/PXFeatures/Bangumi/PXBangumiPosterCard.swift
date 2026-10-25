import SwiftUI

struct PXBangumiPosterCard: View {
    var subject: PXBangumiSubject
    var width: CGFloat = 116

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                PXRemoteImage(url: subject.imageURL, maxPixel: width * 3)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .frame(width: width)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke, lineWidth: 0.6)
                    }
                if let score = subject.scoreText {
                    Text(score)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .frame(height: 18)
                        .background(PXTheme.rating, in: Capsule())
                        .padding(6)
                }
            }
            Text(subject.displayTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(PXTheme.textPrimary)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)
            Text(subject.episodesText ?? subject.airDate ?? "放送中")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(PXTheme.textTertiary)
                .lineLimit(1)
        }
        .frame(width: width, alignment: .leading)
        .pxHoverLift()
    }
}
