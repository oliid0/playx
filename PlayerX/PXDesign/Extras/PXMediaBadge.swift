import SwiftUI
struct PXMediaBadge: View {
    var kind: PXMediaKind
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.symbol).font(.system(size: 8, weight: .bold))
            Text(kind.title).font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(PXTheme.accentSoft)
        .padding(.horizontal, 7).frame(height: 20)
        .background(PXTheme.accent.opacity(0.12), in: Capsule())
    }
}
