import SwiftUI
struct PXTVSidebarButton: View {
    var title: String
    var symbol: String
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 24)
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(selected ? PXTheme.accent : PXTheme.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(selected ? PXTheme.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
