import SwiftUI

struct PXUIEpisodeBadge: View {
    let index: Int
    var body: some View {
        Text("EP\(index)")
            .font(PXFont.mono(9))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(PXTheme.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 4))
    }
}
