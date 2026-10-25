import SwiftUI
struct PXTVRatingLabel: View {
    var rating: Double?
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "star.fill").font(.system(size: 12, weight: .bold))
            Text(PXFormat.rating(rating)).font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundStyle(PXTheme.rating)
    }
}
