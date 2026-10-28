import SwiftUI

/// OcPlayer 风格复制组件 213
struct PXOCUI213: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "film").font(.system(size: 11, weight: .semibold))
            Text("找片").font(PXFont.caption(10))
        }
        .foregroundStyle(PXTheme.rose)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(PXTheme.rose.opacity(0.12), in: Capsule())
    }
}
