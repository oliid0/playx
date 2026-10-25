import SwiftUI
struct PXBadgeStack: View {
    var items: [String]
    var tint: Color = PXTheme.textSecondary
    var body: some View {
        HStack(spacing: 5) {
            ForEach(items, id: \.self) { item in
                PXTag(text: item, tint: tint)
            }
        }
    }
}
