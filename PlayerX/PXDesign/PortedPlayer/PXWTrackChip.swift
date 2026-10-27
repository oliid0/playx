import SwiftUI

struct PXWTrackChip: View {
    let track: PXPlaybackTrack
    let selected: Bool
    var body: some View {
        Text(track.title)
            .font(PXFont.caption(10))
            .foregroundStyle(selected ? PXTheme.background : PXTheme.textSecondary)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(selected ? PXTheme.textPrimary : PXTheme.surfaceMuted, in: Capsule())
    }
}
