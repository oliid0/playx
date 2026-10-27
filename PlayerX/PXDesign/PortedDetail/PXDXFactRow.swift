import SwiftUI

struct PXDXFactRow: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary).frame(width: 14)
            Text(label).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary)
            Spacer()
            Text(value).font(PXFont.body(11)).foregroundStyle(PXTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}
