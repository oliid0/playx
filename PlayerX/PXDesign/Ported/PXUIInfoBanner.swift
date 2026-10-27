import SwiftUI

struct PXUIInfoBanner: View {
    let text: String
    var tint: Color = PXTheme.sky
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill").font(.system(size: 12)).foregroundStyle(tint)
            Text(text).font(PXFont.caption(11)).foregroundStyle(PXTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tint.opacity(0.16)))
    }
}
