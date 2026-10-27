import SwiftUI

struct PXDXAvailabilityBadge: View {
    let count: Int
    var body: some View {
        HStack(spacing: 4) {
            PXUISourceStatusDot(isOnline: count > 0)
            Text(count > 0 ? "\(count) 个可播源" : "暂无源").font(PXFont.caption(9)).foregroundStyle(PXTheme.textTertiary)
        }
    }
}
