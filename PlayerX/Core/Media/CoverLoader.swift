import Foundation
import ImageIO

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// 走 Go 核心的 `cover` action，不是直接拿 `Drama.cover` 的 URL 发请求——有些站源（典型的是
/// 黄果AI）的图片 CDN 校验 Referer，没带正确 Referer 直接 403，真机已经验证过这个现象。
/// `cover` action 在 Go 侧会用站源匹配的 Referer 下载到本地磁盘缓存，返回本机文件路径。
///
/// 这里额外加了三层优化：
/// 1. `NSCache` 内存缓存：首页/搜索/详情来回切时不再反复走 FFI 和磁盘读取；
/// 2. `CGImageSource` 下采样：Go 返回的封面可能是 1080×1440 甚至更大，直接全量解码后
///    放进列表会迅速吃满内存。统一按 720pt 长边解码，3x 屏上 240pt 的卡片也够清晰；
/// 3. 跨平台：iOS/iPadOS 返回 `UIImage`，macOS 返回 `NSImage`，上层只认 `PlatformImage`。
enum CoverLoader {
    private static let memoryCache: NSCache<NSString, PlatformImage> = {
        let cache = NSCache<NSString, PlatformImage>()
        cache.countLimit = 160
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()

    static func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    static func cached(for drama: Drama) -> PlatformImage? {
        memoryCache.object(forKey: cacheKey(for: drama))
    }

    static func load(for drama: Drama, maxPixelSize: CGFloat = 720) async throws -> PlatformImage {
        if let cached = cached(for: drama) {
            return cached
        }
        let result: CoverResult = try await NativeBridge.call(NativeRequest(action: "cover", drama: drama))
        guard let image = decode(path: result.path, maxPixelSize: maxPixelSize) else {
            throw NativeError.invalidResponse
        }
        store(image, for: drama)
        return image
    }

    private static func cacheKey(for drama: Drama) -> NSString {
        // cover URL 变化时（站源换了图）缓存要失效，不能只按 id。
        "\(drama.id)#\(drama.cover ?? "")" as NSString
    }

    private static func store(_ image: PlatformImage, for drama: Drama) {
        let cost = Int(image.size.width * image.size.height * Platform.screenScale * Platform.screenScale * 4)
        memoryCache.setObject(image, forKey: cacheKey(for: drama), cost: cost)
    }

    private static func decode(path: String, maxPixelSize: CGFloat) -> PlatformImage? {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(max(64, maxPixelSize * Platform.screenScale))
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #else
        let scale = Platform.screenScale
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: CGFloat(cgImage.width) / scale, height: CGFloat(cgImage.height) / scale)
        )
        #endif
    }
}
