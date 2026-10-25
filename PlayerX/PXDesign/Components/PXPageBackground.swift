import SwiftUI

struct PXPageBackground: View {
    var accent: Color = PXTheme.accent

    var body: some View {
        ZStack {
            PXTheme.background
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 620
            )
            RadialGradient(
                colors: [PXTheme.rose.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 700
            )
            LinearGradient(
                colors: [.clear, PXTheme.backgroundDeep.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
