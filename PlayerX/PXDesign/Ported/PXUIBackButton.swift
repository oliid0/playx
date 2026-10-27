import SwiftUI

struct PXUIBackButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PXTheme.textPrimary)
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(PXTheme.stroke))
        }
        .buttonStyle(PXUIPressScaleButtonStyle())
    }
}
