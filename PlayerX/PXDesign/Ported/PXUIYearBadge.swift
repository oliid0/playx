import SwiftUI

struct PXUIYearBadge: View {
    let year: String
    var body: some View {
        Text(year).font(PXFont.mono(10)).foregroundStyle(PXTheme.textTertiary)
    }
}
