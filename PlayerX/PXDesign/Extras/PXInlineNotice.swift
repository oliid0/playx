import SwiftUI
struct PXInlineNotice: View {
    var text: String
    var symbol: String = "info.circle.fill"
    var tint: Color = PXTheme.textSecondary
    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(tint)
            Text(text).font(.system(size: 10, weight: .medium)).foregroundStyle(PXTheme.textTertiary).lineSpacing(2)
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 9))
    }
}
