import SwiftUI
struct PXDetailKeywords: View {
    var keywords: [String]
    var body: some View {
        if !keywords.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Text("关键词").font(PXFont.section(16)).foregroundStyle(PXTheme.textPrimary)
                FlowLayout(spacing: 6) {
                    ForEach(keywords, id: \.self) { PXTag(text: $0) }
                }
            }
        }
    }
}
