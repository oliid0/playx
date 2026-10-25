import SwiftUI
struct PXTVEpisodeCell: View {
    var number: Int
    var title: String
    var overview: String?
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(String(format: "%02d", number)).font(PXFont.mono(15)).foregroundStyle(PXTheme.accent).frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textPrimary).lineLimit(1)
                    if let overview { Text(overview).font(.caption2).foregroundStyle(PXTheme.textTertiary).lineLimit(2) }
                }
                Spacer()
                Image(systemName: "play.circle").foregroundStyle(PXTheme.textTertiary)
            }
            .padding(12)
            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.card)
    }
}
