import SwiftUI

/// OcPlayer 风格复制组件 090
struct PXOCUI090: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textSecondary).frame(width: 6, height: 6)
            Text("时长").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
