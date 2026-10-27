import SwiftUI

struct PXDXBackdropHeader: View {
    let drama: Drama
    let url: URL?
    var height: CGFloat = 260
    var body: some View {
        Group {
            if let url { PXRemoteImage(url: url, maxPixel: 1600) }
            else { PXCoverImage(drama: drama, maxPixel: 1200) }
        }
        .frame(maxWidth: .infinity).frame(height: height).clipped()
        .overlay(PXUIArtworkGradient())
    }
}
