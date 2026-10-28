import SwiftUI

/// OcPlayer 风格复制组件 042
struct PXOCUI042: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "wifi").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text("链接").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
