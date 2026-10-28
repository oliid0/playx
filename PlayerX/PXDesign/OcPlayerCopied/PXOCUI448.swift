import SwiftUI

/// OcPlayer 风格复制组件 448
struct PXOCUI448: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "speaker.wave.2.fill").font(.system(size: 11, weight: .semibold))
            Text("下一集").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.textTertiary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.textTertiary.opacity(0.12), in: Capsule())
    }
}
