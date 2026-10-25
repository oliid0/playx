import SwiftUI
struct PXDetailFactGrid: View {
    var facts: [(String, String)]
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                VStack(alignment: .leading, spacing: 2) {
                    Text(fact.0).font(.system(size: 8, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
                    Text(fact.1).font(.system(size: 11, weight: .semibold)).foregroundStyle(PXTheme.textSecondary).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
