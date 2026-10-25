import Foundation

struct PXVideoClip: Codable, Identifiable, Hashable, Sendable {
    var key: String
    var name: String
    var site: String
    var type: String

    var id: String { key }
    var isYouTube: Bool { site.lowercased() == "youtube" }
    var youtubeURL: URL? {
        guard isYouTube else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}
