import SwiftUI

struct PXUISkeletonPoster: View {
    var width: CGFloat = 148

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PXUISkeletonBlock(width: width, height: width * 1.5, radius: PXTheme.posterRadius)
            PXUISkeletonBlock(width: width * 0.78, height: 12)
            PXUISkeletonBlock(width: width * 0.5, height: 9)
        }
    }
}
