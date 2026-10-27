import SwiftUI

struct PXWTimecode: View {
    let seconds: Double
    var body: some View {
        Text(PXFormat.time(seconds)).font(PXFont.mono(10)).foregroundStyle(PXTheme.textSecondary)
    }
}
