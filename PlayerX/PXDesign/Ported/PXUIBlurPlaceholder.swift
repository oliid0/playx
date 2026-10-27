import SwiftUI

struct PXUIBlurPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(PXTheme.surfaceMuted)
            .overlay(
                LinearGradient(colors: [.white.opacity(0.04), .clear, .white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
    }
}
