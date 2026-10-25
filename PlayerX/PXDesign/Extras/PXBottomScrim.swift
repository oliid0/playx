import SwiftUI
struct PXBottomScrim: View {
    var height: CGFloat = 220
    var body: some View {
        LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .top, endPoint: .bottom)
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
    }
}
