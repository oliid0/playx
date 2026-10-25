import SwiftUI
struct PXAvatar: View {
    var url: URL?
    var size: CGFloat = 40
    var fallback: String = "person.fill"
    var body: some View {
        PXRemoteImage(url: url, maxPixel: size * 3)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(PXTheme.strokeStrong, lineWidth: 0.8))
            .overlay {
                if url == nil {
                    Image(systemName: fallback).font(.system(size: size * 0.36)).foregroundStyle(PXTheme.textSecondary)
                }
            }
    }
}
