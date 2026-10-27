import SwiftUI

struct PXTVXDetailMeta: View {
    let items: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 { Circle().fill(PXTheme.textTertiary).frame(width: 3, height: 3) }
                Text(item).font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            }
        }
    }
}
