import SwiftUI
struct PXTVInfoPill: View {
    var text: String
    var tint: Color = PXTheme.textSecondary
    var body: some View {
        Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(tint)
            .padding(.horizontal, 10).frame(height: 28)
            .background(tint.opacity(0.10), in: Capsule())
    }
}
