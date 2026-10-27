import SwiftUI

struct PXDXTitleBlock: View {
    let title: String
    let metadata: PXMediaMetadata?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(PXFont.display(30)).foregroundStyle(PXTheme.textPrimary)
            HStack(spacing: 8) {
                if let year = metadata?.yearText { PXUIYearBadge(year: year) }
                if let rating = metadata?.ratingText { Text(rating).font(PXFont.mono(11)).foregroundStyle(PXTheme.rating) }
                if let runtime = metadata?.runtimeText { Text(runtime).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary) }
                PXDXContentRating(rating: metadata?.contentRating)
            }
        }
    }
}
