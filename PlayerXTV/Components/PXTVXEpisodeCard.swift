import SwiftUI

struct PXTVXEpisodeCard: View {
    let index: Int
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 7).fill(PXTheme.surfaceStrong).frame(height: 86)
            Text("第 \(index) 集").font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
            Text(title).font(PXFont.caption(11)).lineLimit(1)
        }
    }
}
