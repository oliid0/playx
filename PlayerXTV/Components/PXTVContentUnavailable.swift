import SwiftUI
struct PXTVContentUnavailable: View {
    var symbol: String
    var title: String
    var message: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 44, weight: .light)).foregroundStyle(PXTheme.textTertiary)
            Text(title).font(PXFont.title(24)).foregroundStyle(PXTheme.textPrimary)
            Text(message).font(.body).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(50)
    }
}
