import SwiftUI
struct PXRatingStars: View {
    var rating: Double?
    var maximum: Int = 5
    var body: some View {
        let value = (rating ?? 0) / 2
        HStack(spacing: 2) {
            ForEach(0..<maximum, id: \.self) { index in
                Image(systemName: Double(index) + 1 <= value.rounded() ? "star.fill" : "star")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(PXTheme.rating)
            }
        }
        .accessibilityLabel("评分 \(rating ?? 0)")
    }
}
