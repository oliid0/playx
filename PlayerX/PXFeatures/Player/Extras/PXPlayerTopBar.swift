import SwiftUI
struct PXPlayerTopBar: View {
    var title: String
    var episode: String
    var onClose: () -> Void
    var onMore: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onClose) { Image(systemName: "xmark").frame(width: 32, height: 32) }
                .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.white).lineLimit(1)
                Text(episode).font(.system(size: 9)).foregroundStyle(.white.opacity(0.52))
            }
            Spacer()
            Button(action: onMore) { Image(systemName: "ellipsis").frame(width: 32, height: 32) }
                .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
    }
}
