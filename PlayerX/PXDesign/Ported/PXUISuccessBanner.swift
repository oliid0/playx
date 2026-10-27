import SwiftUI

struct PXUISuccessBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(PXTheme.mint)
            Text(text).font(PXFont.caption(11)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PXTheme.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
