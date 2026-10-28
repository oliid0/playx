import SwiftUI

/// OcPlayer 风格复制组件 279
struct PXOCUI279: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 12, weight: .semibold))
                Text("时长").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
