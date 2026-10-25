import Foundation

final class PXMediaServerProvider: ContentProvider {
    let configuration: PXSourceConfiguration
    private let client: PXMediaServerClient
    private var cachedViews: [PXMediaServerView]?

    init(configuration: PXSourceConfiguration) {
        self.configuration = configuration
        self.client = PXMediaServerClient(configuration: configuration)
    }

    var sourceId: String { configuration.id }
    var displayName: String { configuration.displayName }
    var sourceKind: PXSourceKind { configuration.kind }
    var sourceSubtitle: String? {
        let host = configuration.normalizedBaseURL?.host ?? "媒体服务器"
        return "\(configuration.kind.title) · \(host)"
    }
    var configurationID: String? { configuration.id }

    func categories() async throws -> [SourceCategory] {
        let views = try await loadViews()
        let mapped = views
            .filter { !["music", "books"].contains(($0.collectionType ?? "").lowercased()) }
            .map { SourceCategory(id: $0.id, name: $0.displayName) }
        return mapped.isEmpty ? [SourceCategory(id: "", name: "媒体库")] : mapped
    }

    func catalog(category: String, page: Int, query: String?) async throws -> CatalogResult {
        let views = try await loadViews()
        let selected = views.first { $0.id == category } ?? views.first
        let kind = selected?.bestKind
        let includeTypes: String
        if let query, !query.isEmpty {
            includeTypes = "Movie,Series"
        } else {
            switch kind {
            case .movie: includeTypes = "Movie"
            case .series, .anime: includeTypes = "Series"
            default: includeTypes = "Movie,Series,BoxSet"
            }
        }
        let start = max(0, (page - 1) * Self.pageSize)
        let response = try await client.items(
            parentID: query?.isEmpty == false ? nil : selected?.id,
            includeTypes: includeTypes,
            search: query,
            start: start,
            limit: Self.pageSize
        )
        let items = response.items ?? []
        let dramas = items
            .filter { !["season", "episode"].contains(($0.type ?? "").lowercased()) }
            .map {
                PXMediaServerMapping.drama(
                    from: $0,
                    configuration: configuration,
                    libraryKind: selected?.bestKind
                )
            }
        let total = response.totalRecordCount ?? (start + items.count)
        return CatalogResult(
            items: dramas,
            hasMore: start + items.count < total,
            page: page,
            warning: nil,
            localSearch: false,
            fresh: false
        )
    }

    func detail(for drama: Drama) async throws -> DetailResult {
        let item = try await client.item(id: drama.sourceId)
        let views = try await loadViews()
        let libraryKind = views.first(where: { $0.id == item.parentIdForLibrary })?.bestKind
        let mapped = PXMediaServerMapping.drama(from: item, configuration: configuration, libraryKind: libraryKind)
        let type = (item.type ?? "").lowercased()
        if type == "series" || type == "boxset" {
            let episodes = try await client.episodes(seriesID: item.id)
            let chapters = episodes.enumerated().compactMap { index, episode -> Chapter? in
                chapter(for: episode, index: index, seriesItem: item)
            }
            return DetailResult(
                drama: mapped,
                chapters: chapters.isEmpty ? [chapter(for: item, index: 0, seriesItem: nil)].compactMap { $0 } : chapters,
                warning: nil
            )
        }
        let chapter = chapter(for: item, index: 0, seriesItem: nil)
        return DetailResult(drama: mapped, chapters: chapter.map { [$0] } ?? [], warning: nil)
    }

    func resolve(drama: Drama, chapter: Chapter, index: Int, quality: Int?) async throws -> PlaybackPlan {
        let bitrate = quality.map(Self.bitrate)
        let url: URL?
        if let mediaSourceID = chapter.source, !mediaSourceID.isEmpty, chapter.source != configuration.id {
            url = client.streamURL(itemID: chapter.id, mediaSourceID: mediaSourceID, maxBitrate: bitrate)
        } else {
            url = client.streamURL(itemID: chapter.id, mediaSourceID: nil, maxBitrate: bitrate)
        }
        guard let streamURL = url ?? URL(string: chapter.videoUrl) else {
            throw PXMediaServerError.transport("无法生成播放地址")
        }
        return PlaybackPlan(
            url: streamURL.absoluteString,
            headers: client.requestHeaders,
            quality: quality ?? 1080,
            qualities: [2160, 1080, 720],
            local: false
        )
    }

    private func loadViews() async throws -> [PXMediaServerView] {
        if let cachedViews { return cachedViews }
        let views = try await client.views()
        cachedViews = views
        return views
    }

    private func chapter(for item: PXMediaServerItem, index: Int, seriesItem: PXMediaServerItem?) -> Chapter? {
        let sources = item.mediaSources ?? []
        let sourceID = sources.first?.id
        let bitrate = 1080
        guard let url = client.streamURL(itemID: item.id, mediaSourceID: sourceID, maxBitrate: Self.bitrate(bitrate)) else {
            return nil
        }
        let season = item.parentIndexNumber ?? 1
        let episode = item.indexNumber ?? (index + 1)
        let prefix = (item.type ?? "").lowercased() == "episode" ? "S\(season)E\(episode) · " : ""
        return Chapter(
            id: item.id,
            source: sourceID ?? configuration.id,
            title: prefix + item.name,
            videoUrl: url.absoluteString,
            currentEpisode: String(index + 1),
            mediaSize: sources.first?.size,
            pageUrl: nil,
            referer: nil,
            vip: false
        )
    }

    static func bitrate(_ quality: Int) -> Int {
        switch quality {
        case 2160: return 40_000_000
        case 1440: return 20_000_000
        case 1080: return 10_000_000
        case 720: return 4_000_000
        default: return 8_000_000
        }
    }

    static let pageSize = 36
}

private extension PXMediaServerItem {
    /// Jellyfin/Emby 的 `ParentId` 是库 id；详情接口没有直接返回库类型，
    /// 这里用 SeriesId 或 ParentId 作为线索，缺省时交给 item 自身类型判断。
    var parentIdForLibrary: String? { seriesId }
}
