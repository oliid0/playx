import SwiftUI
struct PXTopScrim: View {
    var height: CGFloat = 140
    var body: some View {
        LinearGradient(colors: [.black.opacity(0.62), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
    }
}
