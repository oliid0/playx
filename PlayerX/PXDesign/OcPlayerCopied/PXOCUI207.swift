import SwiftUI

/// OcPlayer 风格复制组件 207
struct PXOCUI207: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "house.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rating)
            Text("更多").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
