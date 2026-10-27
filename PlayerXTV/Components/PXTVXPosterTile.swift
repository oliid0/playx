import SwiftUI

struct PXTVXPosterTile: View {
    let title: String
    let url: URL?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PXRemoteImage(url: url, maxPixel: 500)
                .frame(width: 180, height: 270)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title).font(PXFont.caption(12)).lineLimit(1).frame(width: 180, alignment: .leading)
        }
    }
}
