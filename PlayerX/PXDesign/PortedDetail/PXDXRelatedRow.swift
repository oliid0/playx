import SwiftUI

struct PXDXRelatedRow: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5).fill(PXTheme.surfaceStrong).frame(width: 32, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PXFont.body(11)).lineLimit(1)
                Text(subtitle).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
