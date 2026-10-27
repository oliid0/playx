import SwiftUI

struct PXTVXTransportButton: View {
    let icon: String
    var size: CGFloat = 54
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.34, weight: .semibold))
                .frame(width: size, height: size)
                .background(PXTheme.surface, in: Circle())
        }
        .buttonStyle(.card)
        .foregroundStyle(PXTheme.textPrimary)
    }
}
