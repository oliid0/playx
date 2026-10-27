import SwiftUI

struct PXTVXSearchGrouping<Item: Identifiable>: View {
    let title: String
    let items: [Item]
    let label: (Item) -> String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(PXFont.caption(12)).foregroundStyle(PXTheme.textTertiary)
            ForEach(items) { item in
                Text(label(item)).font(PXFont.body(12)).padding(.vertical, 4)
            }
        }
    }
}
