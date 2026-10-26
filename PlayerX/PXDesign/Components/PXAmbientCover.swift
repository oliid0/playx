import SwiftUI

/// 首页 / 媒体库页的氛围底：用当前内容封面做低亮度、强模糊铺底，
/// 对应 OcPlayer 的 Ambience，不额外下载大图。
struct PXAmbientCover: View {
    let drama: Drama?
    var intensity: Double = 1

    var body: some View {
        ZStack {
            PXTheme.background
            if let drama {
                PXCoverImage(drama: drama, contentMode: .fill, maxPixel: 900, showsPlaceholderIcon: false)
                    .blur(radius: 44)
                    .opacity(0.54 * intensity)
                LinearGradient(
                    colors: [PXTheme.background.opacity(0.30), PXTheme.background.opacity(0.82), PXTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [PXTheme.accent.opacity(0.10), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 700
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
