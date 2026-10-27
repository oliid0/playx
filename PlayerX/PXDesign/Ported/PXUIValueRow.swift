import SwiftUI

struct PXUIValueRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(PXFont.body(12)).foregroundStyle(PXTheme.textSecondary)
            Spacer()
            Text(value).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
        }
        .padding(.vertical, 5)
    }
}
