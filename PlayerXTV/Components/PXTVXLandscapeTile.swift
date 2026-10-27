import SwiftUI

struct PXTVXLandscapeTile: View {
    let title: String
    let subtitle: String?
    let url: URL?
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PXRemoteImage(url: url, maxPixel: 700)
                .frame(width: 300, height: 169)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title).font(PXFont.caption(12)).lineLimit(1)
            if let subtitle { Text(subtitle).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary) }
        }
    }
}
