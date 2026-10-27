import SwiftUI

struct PXTVXBrandHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.tv.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(PXTheme.accent)
            Text("PLAYERX").font(PXFont.title(18)).tracking(1.4)
        }
    }
}
