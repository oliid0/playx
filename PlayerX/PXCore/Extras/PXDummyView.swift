import SwiftUI
/// 供 `#Preview` 使用的占位页面，避免每个 Feature 各写一份。
struct PXPlaceholderView: View {
    var title: String
    var body: some View {
        ZStack {
            PXPageBackground()
            VStack(spacing: 10) {
                PXLogoMark(size: 58)
                Text(title).font(PXFont.title(22)).foregroundStyle(PXTheme.textPrimary)
                Text("该页面正在适配中").font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
            }
        }
    }
}
