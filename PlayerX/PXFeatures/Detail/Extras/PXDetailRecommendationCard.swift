import SwiftUI
struct PXDetailRecommendationCard: View {
    var item: PXMediaRecommendation
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                PXRemoteImage(url: item.posterURL, maxPixel: 400)
                    .frame(width: 108, height: 162)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                Text(item.title).font(.system(size: 10, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                Text(item.yearText ?? item.mediaType.title).font(.system(size: 8)).foregroundStyle(PXTheme.textTertiary)
            }
            .frame(width: 108, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
