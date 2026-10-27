import SwiftUI

struct PXUIEmptyRail: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.body(11))
            .foregroundStyle(PXTheme.textTertiary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 14))
    }
}
