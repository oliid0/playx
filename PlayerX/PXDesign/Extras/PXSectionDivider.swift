import SwiftUI
struct PXSectionDivider: View {
    var title: String
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(PXTheme.stroke).frame(height: 0.5)
            Text(title).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(PXTheme.textTertiary)
            Rectangle().fill(PXTheme.stroke).frame(height: 0.5)
        }
    }
}
