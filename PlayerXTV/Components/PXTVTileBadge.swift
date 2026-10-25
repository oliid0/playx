import SwiftUI
struct PXTVTileBadge: View {
    var text: String
    var body: some View {
        Text(text).font(.system(size: 10, weight: .bold)).foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 6).frame(height: 18)
            .background(PXTheme.accent, in: Capsule())
    }
}
