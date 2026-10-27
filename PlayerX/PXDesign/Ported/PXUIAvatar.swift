import SwiftUI

struct PXUIAvatar: View {
    let url: URL?
    var size: CGFloat = 32
    var body: some View {
        PXRemoteImage(url: url, maxPixel: 160)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(PXTheme.stroke))
    }
}
