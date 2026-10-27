import SwiftUI

struct PXDXOverview: View {
    let text: String?
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text?.isEmpty == false ? text! : "暂无简介")
                .font(PXFont.body(13))
                .foregroundStyle(PXTheme.textSecondary)
                .lineLimit(expanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)
            if let text, text.count > 90 {
                Button(expanded ? "收起" : "展开") { withAnimation(PXTheme.quick) { expanded.toggle() } }
                    .font(PXFont.caption(10)).buttonStyle(.plain).foregroundStyle(PXTheme.accent)
            }
        }
    }
}
