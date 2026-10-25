import SwiftUI
struct PXSourceBadge: View {
    var sourceID: String
    var body: some View {
        Text(sourceID)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(PXTheme.sky)
            .padding(.horizontal, 5).frame(height: 16)
            .background(PXTheme.sky.opacity(0.10), in: Capsule())
    }
}
