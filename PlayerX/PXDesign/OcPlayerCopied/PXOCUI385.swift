import SwiftUI

/// OcPlayer 风格复制组件 385
struct PXOCUI385: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(PXTheme.accent).frame(width: 6, height: 6)
            Text("下一集").font(PXFont.caption(10)).foregroundStyle(PXTheme.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "speaker.wave.2.fill").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.vertical, 7)
    }
}
