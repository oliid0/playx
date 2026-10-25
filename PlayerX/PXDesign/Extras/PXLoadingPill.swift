import SwiftUI
struct PXLoadingPill: View {
    var text: String
    var body: some View {
        HStack(spacing: 7) {
            PXLoadingSpinner(size: 14)
            Text(text).font(.system(size: 10, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.horizontal, 10).frame(height: 26)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
