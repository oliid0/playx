import SwiftUI

struct PXUIIconLabel: View {
    let icon: String
    let text: String
    var tint: Color = PXTheme.textSecondary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(PXFont.caption(11))
        }
        .foregroundStyle(tint)
    }
}
