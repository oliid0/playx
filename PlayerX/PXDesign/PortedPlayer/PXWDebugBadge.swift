import SwiftUI

struct PXWDebugBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.mono(8))
            .foregroundStyle(PXTheme.mint)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(PXTheme.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }
}
