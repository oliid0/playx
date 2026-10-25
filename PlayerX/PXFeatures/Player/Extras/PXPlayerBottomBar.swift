import SwiftUI
struct PXPlayerBottomBar: View {
    var leading: String
    var trailing: String?
    var body: some View {
        HStack {
            Text(leading).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.60))
            Spacer()
            if let trailing { Text(trailing).font(PXFont.mono(9)).foregroundStyle(.white.opacity(0.44)) }
        }
        .padding(.horizontal, 16)
    }
}
