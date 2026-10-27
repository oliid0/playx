import SwiftUI

struct PXTVXTileBadges: View {
    let rating: String?
    let badge: String?
    var body: some View {
        HStack(spacing: 4) {
            if let rating { Text(rating).font(PXFont.mono(9)).foregroundStyle(PXTheme.rating) }
            if let badge { Text(badge).font(PXFont.caption(8)).foregroundStyle(PXTheme.textSecondary) }
        }
    }
}
