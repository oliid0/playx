import SwiftUI
struct PXDivider: View {
    var inset: CGFloat = 0
    var body: some View { Rectangle().fill(PXTheme.stroke).frame(height: 0.5).padding(.leading, inset) }
}
