import SwiftUI

struct PXDXEpisodeStill: View {
    let url: URL?
    var body: some View {
        PXRemoteImage(url: url, maxPixel: 480)
            .frame(width: 128, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
