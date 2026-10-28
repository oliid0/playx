import SwiftUI

/// OcPlayer 风格复制组件 254
struct PXOCUI254: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "pause.fill").font(.system(size: 12, weight: .semibold))
                Text("接下来看").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
