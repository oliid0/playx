import SwiftUI
struct PXTVMediaMetaLine: View {
    var parts: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(parts.filter { !$0.isEmpty }, id: \.self) { part in
                Text(part).font(.system(size: 15, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
            }
        }
    }
}
