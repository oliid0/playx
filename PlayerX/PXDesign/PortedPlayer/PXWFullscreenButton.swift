import SwiftUI

struct PXWFullscreenButton: View {
    let isFullscreen: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PXTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
