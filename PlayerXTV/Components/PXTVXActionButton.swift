import SwiftUI

struct PXTVXActionButton: View {
    let title: String
    let icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(PXFont.caption(12))
        }
        .buttonStyle(.card)
    }
}
