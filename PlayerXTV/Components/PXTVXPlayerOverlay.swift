import SwiftUI

struct PXTVXPlayerOverlay<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack { content }
            .padding(24)
            .background(LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.65)], startPoint: .top, endPoint: .bottom))
    }
}
