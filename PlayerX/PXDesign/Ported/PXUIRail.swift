import SwiftUI

struct PXUIRail<Content: View>: View {
    let title: String
    var subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title).font(PXFont.section(19)).foregroundStyle(PXTheme.textPrimary)
                if let subtitle { Text(subtitle).font(PXFont.caption(10)).foregroundStyle(PXTheme.textTertiary) }
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) { content }
            }
        }
    }
}
