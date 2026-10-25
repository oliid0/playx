import SwiftUI
struct PXPlayerChapterProgress: View {
    var index: Int
    var total: Int
    var progress: Double
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule().fill(PXTheme.accent)
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 2)
            Text("第 \(index + 1) / \(total) 集")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.54))
        }
    }
}
