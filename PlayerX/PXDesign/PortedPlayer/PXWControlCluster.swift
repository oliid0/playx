import SwiftUI

struct PXWControlCluster: View {
    let icon: String
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(PXTheme.surfaceMuted, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
