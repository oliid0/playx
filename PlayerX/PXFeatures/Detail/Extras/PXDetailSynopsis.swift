import SwiftUI
struct PXDetailSynopsis: View {
    var text: String?
    @Binding var expanded: Bool
    var body: some View {
        if let text, !text.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("简介").font(PXFont.section(16)).foregroundStyle(PXTheme.textPrimary)
                Text(text)
                    .font(.system(size: 13)).foregroundStyle(PXTheme.textSecondary).lineSpacing(4)
                    .lineLimit(expanded ? nil : 5)
                if text.count > 120 {
                    Button(expanded ? "收起" : "展开") {
                        withAnimation(PXTheme.standard) { expanded.toggle() }
                    }
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(PXTheme.accent)
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
