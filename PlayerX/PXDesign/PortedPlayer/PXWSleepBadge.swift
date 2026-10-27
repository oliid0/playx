import SwiftUI

struct PXWSleepBadge: View {
    let label: String?
    var body: some View {
        if let label {
            HStack(spacing: 3) {
                Image(systemName: "moon.zzz.fill").font(.system(size: 8))
                Text(label).font(PXFont.mono(8))
            }
            .foregroundStyle(PXTheme.accent)
        }
    }
}
