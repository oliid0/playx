import SwiftUI
struct PXDetailSeasonHeader: View {
    var title: String
    var count: Int?
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title).font(PXFont.section(17)).foregroundStyle(PXTheme.textPrimary)
            if let count { Text("\(count) 集").font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary) }
            Spacer()
        }
    }
}
