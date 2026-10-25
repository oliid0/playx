import SwiftUI
struct PXTVBackdropScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.05), location: 0),
                .init(color: PXTheme.background.opacity(0.72), location: 0.65),
                .init(color: PXTheme.background, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
