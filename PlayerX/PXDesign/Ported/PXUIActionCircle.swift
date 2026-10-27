import SwiftUI

struct PXUIActionCircle: View {
    let icon: String
    var size: CGFloat = 34
    var filled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(filled ? PXTheme.background : PXTheme.textPrimary)
                .frame(width: size, height: size)
                .background(filled ? PXTheme.textPrimary : PXTheme.surface, in: Circle())
                .overlay(Circle().strokeBorder(filled ? .clear : PXTheme.stroke))
        }
        .buttonStyle(PXUIPressScaleButtonStyle())
    }
}
