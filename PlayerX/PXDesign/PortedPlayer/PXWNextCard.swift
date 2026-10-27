import SwiftUI

struct PXWNextCard: View {
    let title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "forward.end.fill").font(.system(size: 11))
                VStack(alignment: .leading, spacing: 1) {
                    Text("接下来").font(PXFont.caption(8)).foregroundStyle(PXTheme.textTertiary)
                    Text(title).font(PXFont.caption(10)).lineLimit(1)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .foregroundStyle(PXTheme.textPrimary)
    }
}
