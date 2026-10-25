import SwiftUI
import ImageIO

@MainActor
final class PXImageMemoryCache {
    static let shared = PXImageMemoryCache()
    private let cache: NSCache<NSURL, PXPlatformImage> = {
        let cache = NSCache<NSURL, PXPlatformImage>()
        cache.countLimit = 220
        cache.totalCostLimit = 160 * 1024 * 1024
        return cache
    }()

    func image(for url: URL) -> PXPlatformImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: PXPlatformImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

struct PXRemoteImage: View {
    var url: URL?
    var contentMode: ContentMode = .fill
    var maxPixel: CGFloat = 1200
    @State private var image: PXPlatformImage?
    @State private var failed = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PXTheme.surfaceMuted
                if let image {
                    Image(pxImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .transition(.opacity)
                } else if failed {
                    Image(systemName: "photo")
                        .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.22, weight: .light))
                        .foregroundStyle(PXTheme.textTertiary)
                } else {
                    PXShimmer()
                }
            }
        }
        .task(id: url) { await load() }
        .accessibilityHidden(true)
    }

    private func load() async {
        image = nil
        failed = false
        guard let url else { failed = true; return }
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
    }
}

enum PXImageLoader {
    static func load(url: URL, maxPixel: CGFloat) async -> PXPlatformImage? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 18
        request.setValue("Mozilla/5.0 (PlayerX)", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else { return nil }
        return decode(data: data, maxPixel: maxPixel)
    }

    private static func decode(data: Data, maxPixel: CGFloat) -> PXPlatformImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(max(96, maxPixel * PXPlatform.screenScale)),
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        #if os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
        return UIImage(cgImage: cgImage)
        #endif
    }
}
