import SwiftUI

struct PXUIMediaBadge: View {
    let kind: PXMediaKind
    var body: some View {
        Text(kind == .movie ? "电影" : "剧集")
            .font(PXFont.caption(9))
            .foregroundStyle(PXTheme.textSecondary)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(PXTheme.background.opacity(0.68), in: RoundedRectangle(cornerRadius: 5))
    }
}
