import Foundation

final class PXWebDAVProvider: ContentProvider {
    let configuration: PXSourceConfiguration
    private let client: PXWebDAVClient
    private var rootEntries: [PXWebDAVEntry]?

    init(configuration: PXSourceConfiguration) {
        self.configuration = configuration
        self.client = PXWebDAVClient(configuration: configuration)
    }

    var sourceId: String { configuration.id }
    var displayName: String { configuration.displayName }
    var sourceKind: PXSourceKind { configuration.kind }
    var sourceSubtitle: String? {
        let host = configuration.normalizedBaseURL?.host ?? "WebDAV"
        return "\(configuration.kind.title) · \(host)"
    }
    var configurationID: String? { configuration.id }

    func categories() async throws -> [SourceCategory] {
        let entries = try await loadRoot()
        let directories = entries.filter(\.isDirectory)
            .map { SourceCategory(id: $0.href, name: $0.decodedName) }
        if directories.isEmpty, entries.contains(where: { !$0.isDirectory && PXProviderSupport.isVideo(path: $0.href) }) {
            return [SourceCategory(id: "", name: "根目录")]
        }
        return directories
    }

    func catalog(category: String, page: Int, query: String?) async throws -> CatalogResult {
        let entries: [PXWebDAVEntry]
        if let query, !query.isEmpty {
            entries = try await searchEntries(query)
        } else if category.isEmpty {
            entries = try await loadRoot()
        } else {
            entries = try await client.list(path: category)
        }
        let filtered = entries
            .filter { $0.isDirectory || PXProviderSupport.isVideo(path: $0.href) }
            .filter { entry in
                guard let query, !query.isEmpty else { return true }
                return entry.decodedName.localizedCaseInsensitiveContains(query)
            }
            .sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
                return $0.decodedName.localizedStandardCompare($1.decodedName) == .orderedAscending
            }
        let start = max(0, (page - 1) * Self.pageSize)
        let slice = Array(filtered.dropFirst(start).prefix(Self.pageSize))
        let dramas = slice.compactMap { entry -> Drama? in
            let kind = Self.kind(for: entry.href, name: entry.decodedName)
            var tags = [configuration.kind.title]
            if entry.isDirectory { tags.append("文件夹") }
            return Drama(
                id: "\(configuration.id):\(entry.href)",
                source: configuration.id,
                sourceId: entry.href,
                title: entry.decodedName,
                description: entry.isDirectory ? "目录 · \(entry.decodedName)" : "来自 \(configuration.displayName)",
                cover: nil,
                episodes: nil,
                category: kind.title,
                vip: false,
                heat: nil,
                onlineDate: nil,
                tags: tags,
                releaseStatus: entry.isDirectory ? "folder" : "file"
            )
        }
        return CatalogResult(
            items: dramas,
            hasMore: start + slice.count < filtered.count,
            page: page,
            warning: nil,
            localSearch: false,
            fresh: false
        )
    }

    func detail(for drama: Drama) async throws -> DetailResult {
        if drama.releaseStatus == "file" {
            guard let url = client.absoluteURL(path: drama.sourceId) else {
                throw PXWebDAVError.transport("无效的文件地址")
            }
            let chapter = Chapter(
                id: drama.sourceId,
                source: configuration.id,
                title: drama.title,
                videoUrl: url.absoluteString,
                currentEpisode: "1",
                mediaSize: nil,
                pageUrl: nil,
                referer: nil,
                vip: false
            )
            return DetailResult(drama: drama, chapters: [chapter], warning: nil)
        }
        let entries = try await client.list(path: drama.sourceId)
        let videos = entries
            .filter { !$0.isDirectory && PXProviderSupport.isVideo(path: $0.href) }
            .sorted { $0.decodedName.localizedStandardCompare($1.decodedName) == .orderedAscending }
        let chapters = videos.enumerated().compactMap { index, entry -> Chapter? in
            guard let url = client.absoluteURL(path: entry.href) else { return nil }
            return Chapter(
                id: "\(drama.sourceId)#\(index)",
                source: configuration.id,
                title: entry.decodedName,
                videoUrl: url.absoluteString,
                currentEpisode: String(index + 1),
                mediaSize: entry.contentLength,
                pageUrl: nil,
                referer: nil,
                vip: false
            )
        }
        var updated = drama
        updated.episodes = chapters.count
        updated.releaseStatus = "folder"
        return DetailResult(drama: updated, chapters: chapters, warning: nil)
    }

    func resolve(drama: Drama, chapter: Chapter, index: Int, quality: Int?) async throws -> PlaybackPlan {
        guard let url = URL(string: chapter.videoUrl) else {
            throw PXWebDAVError.transport("无效的视频地址")
        }
        return PlaybackPlan(
            url: url.absoluteString,
            headers: client.headers,
            quality: quality ?? 0,
            qualities: [],
            local: false
        )
    }

    private func loadRoot() async throws -> [PXWebDAVEntry] {
        if let rootEntries { return rootEntries }
        let entries = try await client.listRoot()
        rootEntries = entries
        return entries
    }

    private func searchEntries(_ query: String) async throws -> [PXWebDAVEntry] {
        var queue = try await loadRoot()
        var result: [PXWebDAVEntry] = []
        var visited = Set<String>()
        var depth = 0
        while !queue.isEmpty, depth < 3 {
            let batch = queue
            queue = []
            for entry in batch {
                guard visited.insert(entry.href).inserted else { continue }
                if entry.isDirectory {
                    if let children = try? await client.list(path: entry.href) { queue.append(contentsOf: children) }
                } else if PXProviderSupport.isVideo(path: entry.href),
                          entry.decodedName.localizedCaseInsensitiveContains(query) {
                    result.append(entry)
                }
            }
            depth += 1
        }
        return result
    }

    static func kind(for path: String, name: String) -> PXMediaKind {
        let haystack = (path + " " + name).lowercased()
        if haystack.contains("anime") || haystack.contains("动漫") || haystack.contains("动画") {
            return .anime
        }
        if haystack.contains("movie") || haystack.contains("电影") || haystack.contains("films") {
            return .movie
        }
        if haystack.contains("documentary") || haystack.contains("纪录") { return .documentary }
        if haystack.contains("variety") || haystack.contains("综艺") { return .variety }
        if haystack.contains("short") || haystack.contains("短剧") { return .shortDrama }
        return .series
    }

    static let pageSize = 60
}
