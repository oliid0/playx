import SwiftUI

struct PXWSignalBadge: View {
    let quality: Int
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "wifi").font(.system(size: 8, weight: .semibold))
            Text(quality == 0 ? "AUTO" : "\(quality)P").font(PXFont.mono(8))
        }
        .foregroundStyle(PXTheme.textSecondary)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
