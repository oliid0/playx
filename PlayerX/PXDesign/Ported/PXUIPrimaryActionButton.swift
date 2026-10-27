import SwiftUI

struct PXUIPrimaryActionButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(PXFont.caption(13))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(PXTheme.textPrimary, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(PXTheme.background)
        }
        .buttonStyle(PXUIPressScaleButtonStyle())
    }
}
