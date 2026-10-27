import SwiftUI

struct PXDXPosterCard: View {
    let drama: Drama
    let remoteURL: URL?
    var body: some View {
        Group {
            if let remoteURL { PXRemoteImage(url: remoteURL, maxPixel: 500) }
            else { PXCoverImage(drama: drama, maxPixel: 500) }
        }
        .frame(width: 118, height: 177)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke))
    }
}
