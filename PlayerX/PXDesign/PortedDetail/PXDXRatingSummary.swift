import SwiftUI

struct PXDXRatingSummary: View {
    let metadata: PXMediaMetadata
    var body: some View {
        HStack(spacing: 12) {
            if let rating = metadata.rating { PXUIScoreRing(score: rating) }
            VStack(alignment: .leading, spacing: 3) {
                Text(metadata.ratingText ?? "暂无评分").font(PXFont.title(20))
                Text("\(metadata.voteCount ?? 0) 人评分").font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
        }
    }
}
