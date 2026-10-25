import Foundation

/// TMDB 数据与“站源条目 → TMDB id”对应关系的本地层。用 JSON 而不是 SQLite：
/// 数据量小、可离线复用，并且完全避开额外数据库依赖。
actor PXMetadataCache {
    static let shared = PXMetadataCache()

    private struct Link: Codable {
        var tmdbID: Int
        var kind: PXMediaKind
        var source: String
        var updatedAt: Date
    }

    private var metadataMemory: [String: PXMediaMetadata] = [:]
    private var seasonMemory: [String: PXSeasonInfo] = [:]
    private var links: [String: Link] = [:]
    private let directory: URL

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent("PlayerXMetadata", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        links = Self.load([String: Link].self, from: directory.appendingPathComponent("links.json")) ?? [:]
    }

    func metadata(tmdbID: Int, kind: PXMediaKind, language: String) -> PXMediaMetadata? {
        metadataMemory[key(tmdbID: tmdbID, kind: kind, language: language)]
    }

    func store(_ metadata: PXMediaMetadata) {
        metadataMemory[key(tmdbID: metadata.tmdbID, kind: metadata.mediaType, language: metadata.language)] = metadata
    }

    func season(tvID: Int, season: Int, language: String) -> PXSeasonInfo? {
        seasonMemory["\(tvID):\(season):\(language)"]
    }

    func store(season: PXSeasonInfo, tvID: Int, language: String) {
        seasonMemory["\(tvID):\(season.seasonNumber):\(language)"] = season
    }

    func link(for dramaID: String) -> (tmdbID: Int, kind: PXMediaKind)? {
        guard let link = links[dramaID] else { return nil }
        return (link.tmdbID, link.kind)
    }

    func saveLink(dramaID: String, tmdbID: Int, kind: PXMediaKind, source: String) {
        links[dramaID] = Link(tmdbID: tmdbID, kind: kind, source: source, updatedAt: Date())
        persistLinks()
    }

    func removeLink(dramaID: String) {
        links.removeValue(forKey: dramaID)
        persistLinks()
    }

    func allLinks() -> [String: (Int, PXMediaKind)] {
        links.mapValues { ($0.tmdbID, $0.kind) }
    }

    private func key(tmdbID: Int, kind: PXMediaKind, language: String) -> String {
        "\(kind.rawValue):\(tmdbID):\(language)"
    }

    private func persistLinks() {
        Self.save(links, to: directory.appendingPathComponent("links.json"))
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
