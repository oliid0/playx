import SwiftUI

struct PXDXActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button { action() } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(title).font(PXFont.caption(9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PXUIPressScaleButtonStyle())
        .foregroundStyle(PXTheme.textSecondary)
    }
}
