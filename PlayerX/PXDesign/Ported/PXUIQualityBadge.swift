import SwiftUI

struct PXUIQualityBadge: View {
    let quality: Int
    var body: some View {
        Text(PXFormat.quality(quality))
            .font(PXFont.mono(9))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(PXTheme.stroke))
    }
}
