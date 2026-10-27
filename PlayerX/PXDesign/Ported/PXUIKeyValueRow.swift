import SwiftUI

struct PXUIKeyValueRow: View {
    let key: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary)
            Spacer(minLength: 12)
            Text(value).font(PXFont.body(12)).foregroundStyle(PXTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
