import SwiftUI
struct PXRetryButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) { Label("重试", systemImage: "arrow.clockwise") }
            .buttonStyle(PXSecondaryButtonStyle(compact: true))
    }
}
