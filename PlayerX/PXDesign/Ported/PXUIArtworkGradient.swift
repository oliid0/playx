import SwiftUI

struct PXUIArtworkGradient: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, PXTheme.background.opacity(0.55), PXTheme.background],
            startPoint: .center, endPoint: .bottom
        )
    }
}
