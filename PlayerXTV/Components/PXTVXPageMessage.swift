import SwiftUI

struct PXTVXPageMessage: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 36, weight: .light)).foregroundStyle(PXTheme.textTertiary)
            Text(title).font(PXFont.section(20))
            Text(message).font(PXFont.body(12)).foregroundStyle(PXTheme.textTertiary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
