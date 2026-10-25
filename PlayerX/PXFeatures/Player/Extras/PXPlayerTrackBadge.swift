import SwiftUI
struct PXPlayerTrackBadge: View {
    var title: String
    var symbol: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 8))
            Text(title).font(.system(size: 8, weight: .semibold)).lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.66))
        .padding(.horizontal, 6).frame(height: 18)
        .background(.white.opacity(0.08), in: Capsule())
    }
}
