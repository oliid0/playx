import SwiftUI

struct PXUIStatsPill: View {
    let icon: String
    let value: String
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 8, weight: .semibold))
            Text(value).font(PXFont.mono(9))
        }
        .foregroundStyle(PXTheme.textTertiary)
    }
}
