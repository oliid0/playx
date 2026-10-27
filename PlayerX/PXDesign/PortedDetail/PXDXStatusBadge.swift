import SwiftUI

struct PXDXStatusBadge: View {
    let status: String?
    var body: some View {
        if let status, !status.isEmpty {
            PXUIPillBadge(text: status, tint: PXTheme.mint)
        }
    }
}
