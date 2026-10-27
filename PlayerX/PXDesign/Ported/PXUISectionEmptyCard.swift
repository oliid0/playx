import SwiftUI

struct PXUISectionEmptyCard: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.body(12))
            .foregroundStyle(PXTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PXTheme.stroke))
    }
}
