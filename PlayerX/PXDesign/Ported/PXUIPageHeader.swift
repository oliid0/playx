import SwiftUI

struct PXUIPageHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(PXFont.caption(9))
                    .tracking(1.2)
                    .foregroundStyle(PXTheme.accent)
            }
            Text(title).font(PXFont.display(30)).foregroundStyle(PXTheme.textPrimary)
            if let subtitle {
                Text(subtitle).font(PXFont.body(12)).foregroundStyle(PXTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
