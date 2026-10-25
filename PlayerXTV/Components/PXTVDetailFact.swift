import SwiftUI
struct PXTVDetailFact: View {
    var title: String
    var value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(PXTheme.textTertiary)
            Text(value).font(.system(size: 17, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(minWidth: 110, alignment: .leading)
    }
}
