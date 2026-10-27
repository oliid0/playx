import SwiftUI

struct PXDXMetaLine: View {
    let items: [String]
    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 { Text("·").foregroundStyle(PXTheme.textTertiary) }
                Text(item).font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary).lineLimit(1)
            }
        }
    }
}
