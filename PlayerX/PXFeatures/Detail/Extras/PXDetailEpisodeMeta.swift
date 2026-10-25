import SwiftUI
struct PXDetailEpisodeMeta: View {
    var airDate: String?
    var runtime: Int?
    var rating: Double?
    var body: some View {
        HStack(spacing: 6) {
            if let airDate { PXTag(text: PXFormat.airDate(airDate)) }
            if let runtime { PXTag(text: PXFormat.runtime(minutes: runtime)) }
            if let rating, rating > 0 { PXRatingBadge(rating: rating) }
        }
    }
}
