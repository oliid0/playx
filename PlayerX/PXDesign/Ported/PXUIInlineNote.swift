import SwiftUI

struct PXUIInlineNote: View {
    let text: String
    var icon: String = "info.circle"
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
            Text(text).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
