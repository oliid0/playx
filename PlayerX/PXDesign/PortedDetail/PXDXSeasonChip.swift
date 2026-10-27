import SwiftUI

struct PXDXSeasonChip: View {
    let season: PXSeasonInfo
    let selected: Bool
    var body: some View {
        Text(season.displayName)
            .font(PXFont.caption(10))
            .foregroundStyle(selected ? PXTheme.background : PXTheme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(selected ? PXTheme.textPrimary : PXTheme.surfaceMuted, in: Capsule())
    }
}
