import SwiftUI

struct PXUISourceStatusDot: View {
    let isOnline: Bool
    var body: some View {
        Circle()
            .fill(isOnline ? PXTheme.mint : PXTheme.textTertiary)
            .frame(width: 6, height: 6)
            .shadow(color: isOnline ? PXTheme.mint.opacity(0.5) : .clear, radius: 4)
    }
}
