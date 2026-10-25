import SwiftUI
struct PXDetailMoreMenu: View {
    var onMatch: () -> Void
    var onBangumi: () -> Void
    var onMoviePilot: () -> Void
    var onShare: () -> Void
    var body: some View {
        Menu {
            Button { onMatch() } label: { Label("匹配 TMDB", systemImage: "sparkles.tv") }
            Button { onBangumi() } label: { Label("Bangumi 追番", systemImage: "calendar") }
            Button { onMoviePilot() } label: { Label("MoviePilot 找片", systemImage: "paperplane") }
            Divider()
            Button { onShare() } label: { Label("分享", systemImage: "square.and.arrow.up") }
        } label: {
            Image(systemName: "ellipsis")
        }
        .buttonStyle(PXIconButtonStyle(size: 42))
    }
}
