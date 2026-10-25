import SwiftUI
struct PXTVSectionTitle: View {
    var title: String
    var subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(PXFont.title(26)).foregroundStyle(PXTheme.textPrimary)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(PXTheme.textTertiary) }
        }
    }
}
