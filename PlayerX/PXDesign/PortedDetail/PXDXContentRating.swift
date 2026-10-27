import SwiftUI

struct PXDXContentRating: View {
    let rating: String?
    var body: some View {
        if let rating, !rating.isEmpty {
            Text(rating)
                .font(PXFont.mono(9))
                .foregroundStyle(PXTheme.textSecondary)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(PXTheme.stroke))
        }
    }
}
