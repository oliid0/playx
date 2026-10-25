import SwiftUI
struct PXTVSearchChip: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
                .padding(.horizontal, 14).frame(height: 36)
                .background(PXTheme.surfaceMuted, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
