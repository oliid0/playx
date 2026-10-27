import SwiftUI

struct PXUIMediaArtwork: View {
    let drama: Drama
    var width: CGFloat = 150
    var height: CGFloat = 225
    var radius: CGFloat = PXTheme.posterRadius

    var body: some View {
        PXCoverImage(drama: drama, maxPixel: 400)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
    }
}
