import SwiftUI

struct PXUISegmentedPill<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    @Binding var selection: Item

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.self) { item in
                Button { withAnimation(PXTheme.quick) { selection = item } } label: {
                    Text(title(item))
                        .font(PXFont.caption(11))
                        .foregroundStyle(selection == item ? PXTheme.background : PXTheme.textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(selection == item ? PXTheme.textPrimary : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(PXTheme.surfaceMuted, in: Capsule())
        .overlay(Capsule().strokeBorder(PXTheme.stroke, lineWidth: 0.6))
    }
}
