import SwiftUI

struct PXTVXHeroMeta: View {
    let rating: String?
    let year: String?
    let genres: String?
    var body: some View {
        HStack(spacing: 10) {
            if let rating { Text(rating).foregroundStyle(PXTheme.rating) }
            if let year { Text(year) }
            if let genres { Text(genres).lineLimit(1) }
        }
        .font(PXFont.caption(11))
        .foregroundStyle(PXTheme.textSecondary)
    }
}
