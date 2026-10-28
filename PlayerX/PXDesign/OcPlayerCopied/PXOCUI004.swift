import SwiftUI

/// OcPlayer 风格复制组件 004
struct PXOCUI004: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "backward.end.fill").font(.system(size: 12, weight: .semibold))
                Text("媒体库").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
