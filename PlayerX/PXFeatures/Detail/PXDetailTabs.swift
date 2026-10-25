import SwiftUI

struct PXDetailTabs: View {
    @Binding var selection: PXDetailTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(PXDetailTab.allCases) { tab in
                    Button {
                        withAnimation(PXTheme.quick) { selection = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.symbol).font(.system(size: 10, weight: .bold))
                            Text(tab.title)
                        }
                        .font(.system(size: 12, weight: selection == tab ? .bold : .medium))
                        .foregroundStyle(selection == tab ? Color.black.opacity(0.86) : PXTheme.textSecondary)
                        .padding(.horizontal, 13)
                        .frame(height: 32)
                        .background(selection == tab ? PXTheme.accent : PXTheme.surfaceMuted, in: Capsule())
                        .overlay(Capsule().strokeBorder(selection == tab ? .clear : PXTheme.stroke, lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.contentPadding)
        }
    }
}
