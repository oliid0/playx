import SwiftUI
struct PXPlayerDanmakuBadge: View {
    var count: Int
    var enabled: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: enabled ? "text.bubble.fill" : "text.bubble").font(.system(size: 10))
                Text("\(count)").font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(enabled ? PXTheme.accent : .white.opacity(0.44))
            .padding(.horizontal, 8).frame(height: 24)
            .background(.black.opacity(0.28), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
