import SwiftUI

/// OcPlayer 风格复制组件 314
struct PXOCUI314: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "forward.fill").font(.system(size: 12, weight: .semibold))
                Text("播放全部").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
