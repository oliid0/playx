import SwiftUI
struct PXWordmark: View {
    var size: CGFloat = 24
    var body: some View {
        HStack(spacing: 7) {
            PXLogoMark(size: size * 0.86)
            Text("PlayerX").font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(PXTheme.textPrimary)
        }
    }
}
