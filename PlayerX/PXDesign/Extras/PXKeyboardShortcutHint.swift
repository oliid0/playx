import SwiftUI
struct PXKeyboardShortcutHint: View {
    var keys: String
    var action: String
    var body: some View {
        HStack(spacing: 4) {
            Text(keys).font(PXFont.mono(8, weight: .bold)).foregroundStyle(PXTheme.textSecondary)
            Text(action).font(.system(size: 8)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 4))
    }
}
