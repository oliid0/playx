import SwiftUI

/// OcPlayer 风格复制组件 050
struct PXOCUI050: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.textSecondary).frame(width: 6, height: 6)
            Text("列表").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "arrow.clockwise").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
