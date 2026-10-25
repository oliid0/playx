import SwiftUI
struct PXDetailRatingPanel: View {
    var rating: Double?
    var voteCount: Int?
    var body: some View {
        HStack(spacing: 10) {
            Text(PXFormat.rating(rating)).font(PXFont.display(30)).foregroundStyle(PXTheme.rating)
            VStack(alignment: .leading, spacing: 2) {
                PXRatingStars(rating: rating)
                Text(voteCount.map { "\(PXFormat.voteCount($0)) 人评分" } ?? "TMDB 评分")
                    .font(.system(size: 8)).foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(PXTheme.rating.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
