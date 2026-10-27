import SwiftUI

struct PXUIContentHeader: View {
    let title: String
    var subtitle: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
                if let subtitle { Text(subtitle).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary) }
            }
            Spacer()
            if let trailing { Text(trailing).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary) }
        }
    }
}
