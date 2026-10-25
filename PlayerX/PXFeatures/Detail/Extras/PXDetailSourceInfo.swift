import SwiftUI
struct PXDetailSourceInfo: View {
    var sourceID: String
    var dramaID: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("内容源").font(.system(size: 9, weight: .bold)).foregroundStyle(PXTheme.textTertiary)
            HStack(spacing: 6) {
                PXSourceBadge(sourceID: sourceID)
                Text(dramaID).font(PXFont.mono(8)).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
            }
        }
        .padding(10)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 9))
    }
}
