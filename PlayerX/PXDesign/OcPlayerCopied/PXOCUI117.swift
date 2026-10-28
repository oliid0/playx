import SwiftUI

/// OcPlayer 风格复制组件 117
struct PXOCUI117: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.rose)
            Text("显示").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
