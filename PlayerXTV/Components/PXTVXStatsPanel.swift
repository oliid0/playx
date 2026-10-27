import SwiftUI

struct PXTVXStatsPanel: View {
    let engine: String
    let resolution: String
    let time: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(engine).font(PXFont.caption(11))
            Text(resolution).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary)
            Text(time).font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
