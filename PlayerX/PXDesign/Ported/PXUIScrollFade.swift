import SwiftUI

struct PXUIScrollFade: View {
    var height: CGFloat = 28
    var body: some View {
        LinearGradient(colors: [PXTheme.background.opacity(0), PXTheme.background], startPoint: .top, endPoint: .bottom)
            .frame(height: height)
            .allowsHitTesting(false)
    }
}
