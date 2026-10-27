import SwiftUI

struct PXUIMetaChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
