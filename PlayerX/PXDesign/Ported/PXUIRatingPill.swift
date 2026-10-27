import SwiftUI

struct PXUIRatingPill: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").font(.system(size: 9))
            Text(String(format: "%.1f", rating)).font(PXFont.mono(11))
        }
        .foregroundStyle(PXTheme.rating)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(PXTheme.rating.opacity(0.12), in: Capsule())
    }
}
