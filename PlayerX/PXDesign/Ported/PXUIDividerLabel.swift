import SwiftUI

struct PXUIDividerLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(PXTheme.stroke).frame(height: 1)
            Text(text).font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary).fixedSize()
            Rectangle().fill(PXTheme.stroke).frame(height: 1)
        }
    }
}
