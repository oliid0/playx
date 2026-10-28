import SwiftUI

/// OcPlayer 风格复制组件 174
struct PXOCUI174: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet").font(.system(size: 12, weight: .semibold))
                Text("画中画").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
