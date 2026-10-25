import SwiftUI
struct PXTagCloud: View {
    var tags: [String]
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in PXTag(text: tag) }
        }
    }
}
