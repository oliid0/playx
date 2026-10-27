import SwiftUI

struct PXTVXNextUpCard: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6).fill(PXTheme.surfaceStrong).frame(width: 86, height: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text("接下来").font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
                Text(title).font(PXFont.caption(12)).lineLimit(1)
                Text(subtitle).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
    }
}
