import SwiftUI

struct PXWNavigationArrow: View {
    let forward: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: forward ? "chevron.right" : "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PXTheme.textPrimary.opacity(0.8))
                .frame(width: 36, height: 58)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
