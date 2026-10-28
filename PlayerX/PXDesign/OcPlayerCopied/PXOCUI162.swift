import SwiftUI

/// OcPlayer 风格复制组件 162
struct PXOCUI162: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus").font(.system(size: 18, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text("确认").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
