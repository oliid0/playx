import SwiftUI

struct PXUIProviderBadge: View {
    let name: String
    let symbol: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 9, weight: .semibold))
            Text(name).font(PXFont.caption(9))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
