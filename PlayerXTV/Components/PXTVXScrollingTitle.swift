import SwiftUI

struct PXTVXScrollingTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(PXFont.caption(12))
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
