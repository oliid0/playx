import Foundation

enum PXUURLNormalizer {
    static func base(_ raw: String) -> URL? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.contains("://") { text = "https://" + text }
        while text.hasSuffix("/") { text.removeLast() }
        return URL(string: text)
    }
    static func join(_ base: URL, path: String) -> URL {
        let clean = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return base.appendingPathComponent(clean)
    }
}
