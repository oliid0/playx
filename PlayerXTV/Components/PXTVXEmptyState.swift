import SwiftUI

struct PXTVXEmptyState: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.body(12))
            .foregroundStyle(PXTheme.textTertiary)
            .frame(maxWidth: .infinity, minHeight: 220)
    }
}
