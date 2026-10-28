import SwiftUI

/// OcPlayer 风格复制组件 294
struct PXOCUI294: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "wifi").font(.system(size: 12, weight: .semibold))
                Text("链接").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
