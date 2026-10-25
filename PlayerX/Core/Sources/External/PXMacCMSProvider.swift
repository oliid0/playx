import Foundation

final class PXMacCMSProvider: ContentProvider {
    let configuration: PXSourceConfiguration
    private let client: PXMacCMSClient

    init(configuration: PXSourceConfiguration) {
        self.configuration = configuration
        self.client = PXMacCMSClient(configuration: configuration)
    }

    var sourceId: String { configuration.id }
    var displayName: String { configuration.displayName }
    var sourceKind: PXSourceKind { .maccms }
    var sourceSubtitle: String? {
        "MacCMS · \(configuration.normalizedBaseURL?.host ?? "")"
    }
    var configurationID: String? { configuration.id }

    func categories() async throws -> [SourceCategory] {
        let categories = try await client.categories()
        return categories.isEmpty ? [SourceCategory(id: "", name: "全部")] : categories
    }

    func catalog(category: String, page: Int, query: String?) async throws -> CatalogResult {
        let response = try await client.items(category: category, page: page, query: query)
        let items = response.list ?? []
        let dramas = items.map { drama(from: $0) }
        let pageCount = response.pageCount ?? 1
        return CatalogResult(
            items: dramas,
            hasMore: page < pageCount,
            page: page,
            warning: response.msg,
            localSearch: false,
            fresh: false
        )
    }

    func detail(for drama: Drama) async throws -> DetailResult {
        guard let item = try await client.item(id: drama.sourceId) else {
            throw PXMacCMSError.transport("MacCMS 上没有这个条目")
        }
        var mapped = self.drama(from: item)
        let chapters = item.playEntries.enumerated().compactMap { index, pair -> Chapter? in
            let (name, raw) = pair
            guard let url = resolvePlayURL(raw) else { return nil }
            return Chapter(
                id: "\(drama.sourceId)#\(index)",
                source: configuration.id,
                title: name,
                videoUrl: url.absoluteString,
                currentEpisode: String(index + 1),
                mediaSize: nil,
                pageUrl: nil,
                referer: configuration.normalizedBaseURL?.absoluteString,
                vip: false
            )
        }
        mapped.episodes = chapters.count
        return DetailResult(drama: mapped, chapters: chapters, warning: nil)
    }

    func resolve(drama: Drama, chapter: Chapter, index: Int, quality: Int?) async throws -> PlaybackPlan {
        guard let url = URL(string: chapter.videoUrl) else {
            throw PXMacCMSError.transport("无效的播放地址")
        }
        var headers = client.headers
        if let referer = chapter.referer, !referer.isEmpty { headers["Referer"] = referer }
        return PlaybackPlan(
            url: url.absoluteString,
            headers: headers,
            quality: quality ?? 0,
            qualities: [],
            local: false
        )
    }

    private func drama(from item: PXMacCMSItem) -> Drama {
        let kind = PXProviderSupport.mediaKind(
            title: item.name,
            genres: [item.typeName ?? ""],
            library: nil
        )
        var tags = [item.typeName, item.area, item.language, item.year]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let from = item.playFrom, !from.isEmpty { tags.append(from) }
        return Drama(
            id: "\(configuration.id):\(item.vodID)",
            source: configuration.id,
            sourceId: item.vodID,
            title: item.name,
            description: PXProviderSupport.stripHTML(item.content),
            cover: resolveImage(item.poster)?.absoluteString,
            episodes: item.playEntries.count > 0 ? item.playEntries.count : nil,
            category: kind.title,
            vip: false,
            heat: nil,
            onlineDate: item.year,
            tags: tags,
            releaseStatus: item.remarks
        )
    }

    private func resolveImage(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        if raw.hasPrefix("http") { return URL(string: raw) }
        if raw.hasPrefix("//") { return URL(string: "https:" + raw) }
        if let base = configuration.normalizedBaseURL {
            return URL(string: raw, relativeTo: base)?.absoluteURL
        }
        return URL(string: raw)
    }

    private func resolvePlayURL(_ raw: String) -> URL? {
        if raw.hasPrefix("http") { return URL(string: raw) }
        if raw.hasPrefix("//") { return URL(string: "https:" + raw) }
        if let base = configuration.normalizedBaseURL {
            return URL(string: raw, relativeTo: base)?.absoluteURL
        }
        return URL(string: raw)
    }
}
