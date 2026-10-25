import SwiftUI
struct PXPlayerMiniInfo: View {
    var title: String
    var subtitle: String?
    var body: some View {
        HStack(spacing: 5) {
            Text(title).font(.system(size: 9, weight: .semibold)).foregroundStyle(.white.opacity(0.70))
            if let subtitle { Text(subtitle).font(.system(size: 8)).foregroundStyle(.white.opacity(0.38)) }
        }
        .padding(.horizontal, 7).frame(height: 20)
        .background(.black.opacity(0.24), in: Capsule())
    }
}
