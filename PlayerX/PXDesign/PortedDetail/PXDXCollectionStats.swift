import SwiftUI

struct PXDXCollectionStats: View {
    let episodes: Int
    let sources: Int
    var body: some View {
        HStack(spacing: 16) {
            stat("剧集", "\(episodes)")
            stat("站源", "\(sources)")
            stat("状态", "可播放")
        }
    }
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(PXFont.title(16))
            Text(title).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
        }
    }
}
