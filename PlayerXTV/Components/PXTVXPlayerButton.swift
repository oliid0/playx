import SwiftUI

struct PXTVXPlayerButton: View {
    let icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .frame(width: 46, height: 46)
        }
        .buttonStyle(.card)
    }
}
