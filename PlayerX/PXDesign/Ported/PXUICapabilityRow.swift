import SwiftUI

struct PXUICapabilityRow: View {
    let title: String
    let enabled: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: enabled ? "checkmark.circle.fill" : "minus.circle")
                .font(.system(size: 10))
                .foregroundStyle(enabled ? PXTheme.mint : PXTheme.textTertiary)
            Text(title).font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
    }
}
