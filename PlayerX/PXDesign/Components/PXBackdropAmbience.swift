import SwiftUI

/// 详情/首页的全幅氛围图。大图用模糊铺底，再叠一层暗色保证文字对比度。
struct PXBackdropAmbience: View {
    var url: URL?
    var intensity: Double = 1

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let url {
                    PXRemoteImage(url: url, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .blur(radius: 28 * intensity)
                        .opacity(0.74 * intensity)
                        .overlay(PXTheme.background.opacity(0.30))
                }
                LinearGradient(
                    colors: [
                        PXTheme.background.opacity(0.22),
                        PXTheme.background.opacity(0.64),
                        PXTheme.background,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
