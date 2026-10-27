import SwiftUI

struct PXTVXPlayerInfo: View {
    let title: String
    let subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(PXFont.title(20)).lineLimit(1)
            if let subtitle { Text(subtitle).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary) }
        }
    }
}
