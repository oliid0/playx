import SwiftUI

struct PXTVXRailHeader: View {
    let title: String
    let subtitle: String?
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(PXFont.section(22))
            if let subtitle { Text(subtitle).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary) }
            Spacer()
        }
    }
}
