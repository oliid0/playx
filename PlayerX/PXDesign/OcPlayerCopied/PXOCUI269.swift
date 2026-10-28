import SwiftUI

/// OcPlayer 风格复制组件 269
struct PXOCUI269: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2").font(.system(size: 12, weight: .semibold))
                Text("下载").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
