import SwiftUI
struct PXDetailMatchStatus: View {
    var metadata: PXMediaMetadata?
    var isLoading: Bool
    var body: some View {
        HStack(spacing: 6) {
            if isLoading {
                PXLoadingSpinner(size: 11)
                Text("正在匹配 TMDB…")
            } else if let metadata {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(PXTheme.mint)
                Text("TMDB \(metadata.tmdbID)")
            } else {
                Image(systemName: "questionmark.circle").foregroundStyle(PXTheme.textTertiary)
                Text("未匹配元数据")
            }
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(PXTheme.textTertiary)
    }
}
