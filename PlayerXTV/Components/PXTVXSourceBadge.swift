import SwiftUI

struct PXTVXSourceBadge: View {
    let name: String
    let symbol: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 9))
            Text(name).font(PXFont.caption(9))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
