import SwiftUI

struct PXUIBadgeCounter: View {
    let count: Int
    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(PXTheme.background)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(PXTheme.accent, in: Capsule())
        }
    }
}
