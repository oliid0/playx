import SwiftUI

struct PXUIUnderlineTabs<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    @Binding var selection: Item

    var body: some View {
        HStack(spacing: 18) {
            ForEach(items, id: \.self) { item in
                Button { withAnimation(PXTheme.quick) { selection = item } } label: {
                    VStack(spacing: 6) {
                        Text(title(item))
                            .font(PXFont.caption(12))
                            .foregroundStyle(selection == item ? PXTheme.textPrimary : PXTheme.textTertiary)
                        Capsule()
                            .fill(selection == item ? PXTheme.accent : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
