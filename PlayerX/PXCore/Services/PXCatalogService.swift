import Foundation

/// 站源目录聚合。站源就像 Emby/Jellyfin 的媒体库：每个源自己有一套分类，
/// 我们按用户想看的媒体类型（电影/剧集/动漫…）挑选对应分类，再把各源结果
/// 交错合并成一面内容墙。
@MainActor
final class PXCatalogService {
    static let shared = PXCatalogService()

    struct Page {
        var items: [PXCatalogEntry]
        var hasMore: Bool
        var warnings: [String]
    }

    struct SearchReport {
        var entries: [PXCatalogEntry]
        var sourceCounts: [String: Int]
        var warnings: [String]
    }

    private var categoriesBySource: [String: [SourceCategory]] = [:]
    private let settings = PXAppSettings.shared

    var visibleSources: [SourceDescriptor] {
        var sources = SourceRegistry.all.filter { descriptor in
            descriptor.defaultVisible || SourceLockStore.shared.isUnlockedThisLaunch
        }
        let selected = settings.preferredSourceIDs
        if !selected.isEmpty {
            // 站源开关只过滤内置站源；用户显式添加的外部媒体源由配置的 enabled 控制。
            sources = sources.filter { $0.isExternal || selected.contains($0.id) }
        }
        return sources
    }

    /// 搜索不按「首页可见」过滤：所有内置站源 + 所有已启用外部源都要参与。
    /// 锁只影响首页展示，不应让用户在搜索时丢掉整批站源。
    var searchSources: [SourceDescriptor] {
        SourceRegistry.all.filter { descriptor in
            if descriptor.isExternal {
                guard let configurationID = descriptor.configurationID else { return false }
                return PXSourceConfigurationStore.shared.enabledConfigurations.contains { $0.id == configurationID }
            }
            return true
        }
    }

    func categories(for descriptor: SourceDescriptor) async -> [SourceCategory] {
        if let cached = categoriesBySource[descriptor.id] { return cached }
        let values = (try? await descriptor.provider.categories()) ?? []
        categoriesBySource[descriptor.id] = values
        return values
    }

    func items(
        section: PXCatalogSection,
        page: Int = 1,
        filter: PXCatalogFilter = .init()
    ) async -> Page {
        let descriptors = visibleSources
        guard !descriptors.isEmpty else {
            return Page(items: [], hasMore: false, warnings: ["没有可用站源"])
        }
        let kind = filter.kind ?? section.mediaKind
        let result = await withTaskGroup(of: (Int, [Drama], String?).self) { group in
            for (index, descriptor) in descriptors.prefix(8).enumerated() {
                group.addTask {
                    let category = await Self.categoryID(for: kind, descriptor: descriptor)
                    do {
                        let response = try await descriptor.provider.catalog(
                            category: category, page: page, query: nil
                        )
                        return (index, response.items, response.warning)
                    } catch {
                        return (index, [], error.localizedDescription)
                    }
                }
            }
            var buckets: [Int: [Drama]] = [:]
            var warnings: [String] = []
            var hasMore = false
            for await (index, items, warning) in group {
                buckets[index] = items
                if let warning, !warning.isEmpty { warnings.append(warning) }
                if !items.isEmpty { hasMore = true }
            }
            // 交错合并：第一轮每源 1 条，第二轮每源第 2 条……避免打开页面
            // 先看到某个源一整屏、其它源全在下面。
            var merged: [Drama] = []
            var seen = Set<String>()
            let maxCount = buckets.values.map(\.count).max() ?? 0
            for offset in 0..<maxCount {
                for index in descriptors.indices where buckets[index]?.indices.contains(offset) == true {
                    if let item = buckets[index]?[offset], seen.insert(item.id).inserted {
                        merged.append(item)
                    }
                }
            }
            return (merged, hasMore, warnings)
        }
        var entries = result.0.compactMap { drama -> PXCatalogEntry? in
            guard let descriptor = SourceRegistry.descriptor(for: drama.source)
                ?? descriptors.first(where: { $0.id == drama.source }) else { return nil }
            return PXCatalogEntry(drama: drama, section: section, providerID: descriptor.id)
        }
        entries = apply(filter, to: entries)
        return Page(items: entries, hasMore: result.1, warnings: result.2)
    }

    func homeFeed() async -> [PXHomeRail] {
        let descriptors = Array(visibleSources.prefix(6))
        guard !descriptors.isEmpty else { return [] }
        var rails: [PXHomeRail] = []
        await withTaskGroup(of: (Int, [Drama]).self) { group in
            for (index, descriptor) in descriptors.enumerated() {
                group.addTask {
                    do {
                        let items = try await descriptor.provider.catalog(category: "", page: 1, query: nil).items
                        return (index, items)
                    } catch { return (index, []) }
                }
            }
            var buckets: [Int: [Drama]] = [:]
            for await (index, items) in group { buckets[index] = items }
            for (index, descriptor) in descriptors.enumerated() {
                guard let items = buckets[index], !items.isEmpty else { continue }
                let entries = items.compactMap { drama -> PXCatalogEntry? in
                    PXCatalogEntry(
                        drama: drama,
                        section: Self.section(for: drama.pxKind),
                        providerID: descriptor.id
                    )
                }
                rails.append(PXHomeRail(
                    id: "source-\(descriptor.id)",
                    title: "\(descriptor.displayName)精选",
                    subtitle: Self.sourceTagline(descriptor.id),
                    symbol: "play.rectangle.fill",
                    style: .landscape,
                    entries: Array(entries.prefix(14)),
                    seeAllSection: Self.section(for: items.first?.pxKind ?? .series)
                ))
            }
        }
        return rails.sorted { $0.id < $1.id }
    }

    func search(query: String, scope: PXSearchScope, section: PXCatalogSection = .library) async -> [PXCatalogEntry] {
        await searchReport(query: query, scope: scope, section: section).entries
    }

    func searchReport(query: String, scope: PXSearchScope, section: PXCatalogSection = .library) async -> SearchReport {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return SearchReport(entries: [], sourceCounts: [:], warnings: []) }
        let descriptors = searchSources
        guard !descriptors.isEmpty else {
            return SearchReport(entries: [], sourceCounts: [:], warnings: ["没有可搜索的站源"])
        }

        struct Bucket {
            var index: Int
            var descriptor: SourceDescriptor
            var entries: [PXCatalogEntry]
            var warning: String?
            var topScore: Int
        }

        let buckets = await withTaskGroup(of: Bucket.self) { group -> [Bucket] in
            for (index, descriptor) in descriptors.enumerated() {
                group.addTask {
                    let outcome = await Self.searchOne(descriptor: descriptor, query: trimmed, section: section)
                    return Bucket(index: index, descriptor: descriptor, entries: outcome.entries,
                                  warning: outcome.warning, topScore: outcome.topScore)
                }
            }
            var values: [Bucket] = []
            for await bucket in group { values.append(bucket) }
            return values
        }

        let sortedBuckets = buckets
            .filter { !$0.entries.isEmpty || $0.warning != nil }
            .sorted { lhs, rhs in
                if lhs.topScore != rhs.topScore { return lhs.topScore > rhs.topScore }
                return lhs.index < rhs.index
            }

        var merged: [PXCatalogEntry] = []
        var seen = Set<String>()
        let maxCount = sortedBuckets.map(\.entries.count).max() ?? 0
        for offset in 0..<maxCount {
            for bucket in sortedBuckets where bucket.entries.indices.contains(offset) {
                let entry = bucket.entries[offset]
                if seen.insert(entry.id).inserted { merged.append(entry) }
            }
        }
        var counts: [String: Int] = [:]
        for bucket in sortedBuckets where !bucket.entries.isEmpty {
            counts[bucket.descriptor.id] = bucket.entries.count
        }
        return SearchReport(
            entries: merged,
            sourceCounts: counts,
            warnings: sortedBuckets.compactMap(\.warning)
        )
    }

    private struct SearchOneOutcome {
        var entries: [PXCatalogEntry]
        var warning: String?
        var topScore: Int
    }

    private nonisolated static func searchOne(
        descriptor: SourceDescriptor,
        query: String,
        section: PXCatalogSection
    ) async -> SearchOneOutcome {
        let task = Task {
            try await descriptor.provider.catalog(category: "", page: 1, query: query)
        }
        let timeout = Task {
            try? await Task.sleep(nanoseconds: 9_000_000_000)
        }
        let result = await withTaskGroup(of: Result<CatalogResult, Error>?.self) { group -> Result<CatalogResult, Error>? in
            group.addTask {
                do { return .success(try await task.value) }
                catch { return .failure(error) }
            }
            group.addTask {
                _ = await timeout.value
                return nil
            }
            let first = await group.next()
            group.cancelAll()
            task.cancel()
            timeout.cancel()
            return first ?? nil
        }
        guard let result else {
            return SearchOneOutcome(entries: [], warning: "\(descriptor.displayName) 搜索超时", topScore: 0)
        }
        switch result {
        case .failure(let error):
            return SearchOneOutcome(entries: [], warning: "\(descriptor.displayName)：\(error.localizedDescription)", topScore: 0)
        case .success(let response):
            var entries: [PXCatalogEntry] = []
            var seen = Set<String>()
            var topScore = 0
            for drama in response.items {
                guard seen.insert(drama.id).inserted else { continue }
                guard let score = PXSearchMatcher.score(title: drama.title, subtitle: drama.category,
                                                        overview: drama.description, query: query) else { continue }
                topScore = max(topScore, score)
                entries.append(PXCatalogEntry(drama: drama, section: section, providerID: descriptor.id))
            }
            entries.sort {
                let left = PXSearchMatcher.score(title: $0.drama.title, subtitle: $0.drama.category,
                                                overview: $0.drama.description, query: query) ?? 0
                let right = PXSearchMatcher.score(title: $1.drama.title, subtitle: $1.drama.category,
                                                 overview: $1.drama.description, query: query) ?? 0
                if left != right { return left > right }
                return $0.drama.title.localizedStandardCompare($1.drama.title) == .orderedAscending
            }
            var warning = response.warning
            if response.items.isEmpty == false && entries.isEmpty {
                warning = "\(descriptor.displayName) 返回了 \(response.items.count) 条，但均与关键词无关"
            }
            return SearchOneOutcome(entries: entries, warning: warning, topScore: topScore)
        }
    }

    func genres(for section: PXCatalogSection) -> [String] {
        switch section {
        case .movies: ["剧情", "动作", "喜剧", "科幻", "爱情", "悬疑", "恐怖", "动画"]
        case .series: ["剧情", "悬疑", "犯罪", "古装", "都市", "家庭", "战争", "奇幻"]
        case .anime: ["热血", "恋爱", "奇幻", "日常", "机战", "悬疑", "治愈", "剧场版"]
        case .shorts: ["甜宠", "逆袭", "复仇", "悬疑", "古装", "都市", "重生", "虐恋"]
        case .variety: ["真人秀", "脱口秀", "音乐", "竞技", "访谈", "生活"]
        case .documentary: ["自然", "历史", "人文", "科技", "美食", "旅行"]
        default: []
        }
    }

    func years() -> [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 12)...current).reversed()
    }

    private func apply(_ filter: PXCatalogFilter, to entries: [PXCatalogEntry]) -> [PXCatalogEntry] {
        var result = entries
        if let kind = filter.kind {
            result = result.filter { $0.drama.pxKind == kind }
        }
        if let source = filter.sourceID {
            result = result.filter { $0.providerID == source }
        }
        if let genre = filter.genre {
            result = result.filter { $0.drama.pxGenres.contains { $0.localizedCaseInsensitiveContains(genre) } }
        }
        if let year = filter.year {
            result = result.filter { $0.drama.pxYear == year }
        }
        switch filter.sort {
        case .recommended:
            break
        case .newest:
            result.sort { ($0.drama.pxYear ?? 0) > ($1.drama.pxYear ?? 0) }
        case .rating:
            result.sort { ($0.drama.heat ?? "") > ($1.drama.heat ?? "") }
        case .title:
            result.sort { $0.drama.title.localizedStandardCompare($1.drama.title) == .orderedAscending }
        case .episodes:
            result.sort { ($0.drama.pxEpisodeCount ?? 0) > ($1.drama.pxEpisodeCount ?? 0) }
        }
        return result
    }

    nonisolated private static func categoryID(for kind: PXMediaKind?, descriptor: SourceDescriptor) async -> String {
        guard let kind else { return "" }
        let categories = (try? await descriptor.provider.categories()) ?? []
        let keywords: [String]
        switch kind {
        case .movie: keywords = ["电影", "影片", "片库", "movie"]
        case .series: keywords = ["电视剧", "剧集", "连续剧", "剧", "tv", "series"]
        case .anime: keywords = ["动漫", "动画", "番剧", "二次元", "anime", "剧集", "tv", "series"]
        case .shortDrama: keywords = ["短剧", "竖屏", "微短剧", "剧集", "tv"]
        case .variety: keywords = ["综艺", "真人秀"]
        case .documentary: keywords = ["纪录", "纪实"]
        }
        for keyword in keywords {
            if let match = categories.first(where: {
                $0.name.localizedCaseInsensitiveContains(keyword)
            }) { return match.id }
        }
        return ""
    }

    nonisolated static func section(for kind: PXMediaKind) -> PXCatalogSection {
        switch kind {
        case .movie: .movies
        case .series: .series
        case .anime: .anime
        case .shortDrama: .shorts
        case .variety: .variety
        case .documentary: .documentary
        }
    }

    nonisolated static func sourceTagline(_ id: String) -> String {
        if let descriptor = SourceRegistry.descriptor(for: id), descriptor.isExternal {
            return descriptor.subtitle ?? descriptor.kind.title
        }
        return switch id {
        case "hongguo": "竖屏热播 · 每日更新"
        case "hanxiaoquan": "韩剧 / 韩综精选"
        case "guipian": "恐怖 / 惊悚 / 悬疑"
        case "sorani": "新番 / 剧场版 / 国创"
        case "huangdou": "电影 / 剧集片库"
        case "huangju": "高分剧集"
        case "yeguo": "全网热播"
        case "dsd": "独家片单"
        default: "持续更新"
        }
    }
}
