import SwiftUI

struct PXWDanmakuToggle: View {
    let enabled: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: enabled ? "text.bubble.fill" : "text.bubble")
                .font(.system(size: 13))
                .foregroundStyle(enabled ? PXTheme.textPrimary : PXTheme.textTertiary)
        }
        .buttonStyle(.plain)
    }
}
