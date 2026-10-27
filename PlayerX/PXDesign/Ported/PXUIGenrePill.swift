import SwiftUI

struct PXUIGenrePill: View {
    let title: String
    var body: some View {
        Text(title)
            .font(PXFont.caption(10))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(PXTheme.surfaceMuted, in: Capsule())
            .overlay(Capsule().strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
