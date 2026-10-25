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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let descriptors = visibleSources
        let result = await withTaskGroup(of: (Int, [Drama]).self) { group in
            for (index, descriptor) in descriptors.enumerated() {
                group.addTask {
                    do {
                        var all: [Drama] = []
                        var seen = Set<String>()
                        for category in ["", "电影", "电视剧", "动漫"] {
                            let response = try await descriptor.provider.catalog(
                                category: category, page: 1, query: trimmed
                            )
                            for item in response.items where seen.insert(item.id).inserted {
                                all.append(item)
                            }
                            if !all.isEmpty { break }
                        }
                        return (index, all)
                    } catch { return (index, []) }
                }
            }
            var buckets: [Int: [Drama]] = [:]
            for await (index, items) in group { buckets[index] = items }
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
            return merged
        }
        return result.compactMap { drama in
            guard let descriptor = SourceRegistry.descriptor(for: drama.source) else { return nil }
            return PXCatalogEntry(drama: drama, section: section, providerID: descriptor.id)
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
        case .series: keywords = ["电视剧", "剧集", "连续剧", "剧", "tv"]
        case .anime: keywords = ["动漫", "动画", "番剧", "二次元", "anime"]
        case .shortDrama: keywords = ["短剧", "竖屏", "微短剧"]
        case .variety: keywords = ["综艺", "真人秀"]
        case .documentary: keywords = ["纪录", "纪实"]
        }
        for keyword in keywords {
            if let match = categories.first(where: {
                $0.name.localizedCaseInsensitiveContains(keyword)
            }) { return match.id }
        }
        return categories.first(where: { !$0.id.isEmpty })?.id ?? ""
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
        switch id {
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
