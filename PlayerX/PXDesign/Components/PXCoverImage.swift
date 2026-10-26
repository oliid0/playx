import SwiftUI

/// 统一封面：内置站源必须走 Go 的 `cover` action（部分 CDN 校验 Referer），
/// 外部媒体源则是普通 http(s) 图片。上层的卡片只认识 `Drama`，不关心来源。
struct PXCoverImage: View {
    let drama: Drama
    var contentMode: ContentMode = .fill
    var maxPixel: CGFloat = 900
    var showsPlaceholderIcon: Bool = true

    @State private var image: PXPlatformImage?
    @State private var failed = false

    private var isExternal: Bool {
        SourceRegistry.descriptor(for: drama.source)?.isExternal == true
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                placeholder
                if let image {
                    Image(pxImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .transition(.opacity)
                }
            }
        }
        .task(id: "\(drama.id)#\(drama.cover ?? "")#\(isExternal)") { await load() }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [PXTheme.surfaceStrong, PXTheme.surfaceMuted],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if showsPlaceholderIcon {
                Image(systemName: failed ? "photo.badge.exclamationmark" : "photo")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(PXTheme.textTertiary)
            }
        }
    }

    private func load() async {
        image = nil
        failed = false
        guard drama.cover?.isEmpty == false else {
            failed = true
            return
        }
        if isExternal {
            guard let url = URL(string: drama.cover ?? "") else { failed = true; return }
            if let cached = PXImageMemoryCache.shared.image(for: url) {
                image = cached
                return
            }
            if let loaded = await PXImageLoader.load(url: url, maxPixel: maxPixel) {
                PXImageMemoryCache.shared.insert(loaded, for: url)
                image = loaded
            } else {
                failed = true
            }
        } else {
            if let cached = CoverLoader.cached(for: drama) {
                image = cached
                return
            }
            do {
                image = try await CoverLoader.load(for: drama, maxPixelSize: maxPixel)
            } catch {
                failed = true
            }
        }
    }
}
