import SwiftUI

/// OcPlayer 风格复制组件 402
struct PXOCUI402: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "film").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text("找片").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
