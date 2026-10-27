import SwiftUI

struct PXWTopTitle: View {
    let title: String
    let subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(PXFont.caption(13)).lineLimit(1)
            if let subtitle { Text(subtitle).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary).lineLimit(1) }
        }
    }
}
