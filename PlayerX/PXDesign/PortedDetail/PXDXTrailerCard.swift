import SwiftUI

struct PXDXTrailerCard: View {
    let clip: PXVideoClip
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PXRemoteImage(url: URL(string: "https://img.youtube.com/vi/\(clip.key)/hqdefault.jpg"), maxPixel: 500)
                .frame(width: 200, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(PXUIPlayGlyph(size: 34))
            Text(clip.name.isEmpty ? "预告片" : clip.name).font(PXFont.caption(11)).lineLimit(1).frame(width: 200, alignment: .leading)
        }
    }
}
