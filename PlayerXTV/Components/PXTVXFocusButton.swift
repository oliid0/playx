import SwiftUI

struct PXTVXFocusButton: View {
    let title: String
    let icon: String?
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title).font(PXFont.caption(12))
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
        }
        .buttonStyle(.card)
    }
}
