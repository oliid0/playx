import SwiftUI
struct PXDetailActionRow: View {
    var isFavorite: Bool
    var onPlay: () -> Void
    var onFavorite: () -> Void
    var onDownload: () -> Void
    var body: some View {
        HStack(spacing: 9) {
            Button(action: onPlay) { Label("播放", systemImage: "play.fill").frame(minWidth: 110) }
                .buttonStyle(PXPrimaryButtonStyle())
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart").frame(width: 42, height: 42)
            }
            .buttonStyle(PXIconButtonStyle(size: 44))
            .foregroundStyle(isFavorite ? PXTheme.rose : PXTheme.textPrimary)
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle").frame(width: 42, height: 42)
            }
            .buttonStyle(PXIconButtonStyle(size: 44))
        }
    }
}
