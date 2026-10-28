import SwiftUI

/// OcPlayer 风格复制组件 317
struct PXOCUI317: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "pause.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rose)
            Text("接下来看").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
