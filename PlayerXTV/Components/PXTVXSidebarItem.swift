import SwiftUI

struct PXTVXSidebarItem: View {
    let title: String
    let icon: String
    let selected: Bool
    var body: some View {
        Label(title, systemImage: icon)
            .font(PXFont.caption(13))
            .foregroundStyle(selected ? PXTheme.textPrimary : PXTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? PXTheme.surfaceStrong : .clear, in: RoundedRectangle(cornerRadius: 8))
    }
}
