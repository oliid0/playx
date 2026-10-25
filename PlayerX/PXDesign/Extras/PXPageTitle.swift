import SwiftUI
struct PXPageTitle: View {
    var title: String
    var subtitle: String?
    var symbol: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let symbol { Image(systemName: symbol).font(.system(size: 17, weight: .bold)).foregroundStyle(PXTheme.accent) }
                Text(title).font(PXFont.display(32)).foregroundStyle(PXTheme.textPrimary)
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle).font(PXFont.caption(11)).foregroundStyle(PXTheme.textTertiary)
            }
        }
    }
}
