import SwiftUI
struct PXPlayerScreenshotButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("截图", systemImage: "camera")
                .font(.system(size: 10, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.68))
    }
}
