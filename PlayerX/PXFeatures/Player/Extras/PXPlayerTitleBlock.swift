import SwiftUI
struct PXPlayerTitleBlock: View {
    var title: String
    var subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1)
            if let subtitle { Text(subtitle).font(.system(size: 10)).foregroundStyle(.white.opacity(0.58)).lineLimit(1) }
        }
    }
}
