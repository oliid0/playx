import SwiftUI

/// OcPlayer 风格复制组件 184
struct PXOCUI184: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 12, weight: .semibold))
                Text("帮助").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
