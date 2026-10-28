import SwiftUI

/// OcPlayer 风格复制组件 444
struct PXOCUI444: View {
    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: "forward.end.fill").font(.system(size: 12, weight: .semibold))
                Text("最近添加").font(PXFont.caption(10))
            }
            .foregroundStyle(PXTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PXTheme.surface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}
