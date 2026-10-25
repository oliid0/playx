import Foundation

enum PXImageURL {
    static func poster(_ path: String?, width: Int = 500) -> URL? {
        image(path, size: nearest(width, [92, 154, 185, 342, 500, 780]))
    }

    static func backdrop(_ path: String?, width: Int = 1280) -> URL? {
        image(path, size: nearest(width, [300, 780, 1280, 1920]))
    }

    static func profile(_ path: String?, width: Int = 300) -> URL? {
        image(path, size: nearest(width, [45, 185, 300, 500]))
    }

    static func still(_ path: String?, width: Int = 640) -> URL? {
        image(path, size: nearest(width, [300, 640, 1280]))
    }

    static func logo(_ path: String?, width: Int = 500) -> URL? {
        image(path, size: nearest(width, [154, 300, 500, 780]))
    }

    private static func nearest(_ width: Int, _ sizes: [Int]) -> String {
        if let found = sizes.first(where: { $0 >= width }) { return "w\(found)" }
        return "original"
    }

    private static func image(_ path: String?, size: String) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }

    static func proxied(_ raw: String?, referer: String? = nil) -> URL? {
        guard let raw, let url = URL(string: raw) else { return nil }
        return url
    }
}
