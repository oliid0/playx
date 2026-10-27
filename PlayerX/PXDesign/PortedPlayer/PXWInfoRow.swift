import SwiftUI

struct PXWInfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
            Spacer()
            Text(value).font(PXFont.mono(9)).foregroundStyle(PXTheme.textSecondary)
        }
        .padding(.vertical, 3)
    }
}
