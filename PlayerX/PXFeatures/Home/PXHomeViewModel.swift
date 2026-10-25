import Foundation
import Combine

@MainActor
final class PXHomeViewModel: ObservableObject {
    @Published private(set) var heroItems: [PXHeroItem] = []
    @Published private(set) var rails: [PXHomeRail] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var sources: [SourceDescriptor] = []

    private let catalog: PXCatalogService
    private let metadata: PXMetadataCoordinator
    private var didLoad = false
    private var generation = 0

    init(catalog: PXCatalogService = .shared, metadata: PXMetadataCoordinator = .shared) {
        self.catalog = catalog
        self.metadata = metadata
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await reload()
    }

    func reload() async {
        generation += 1
        let current = generation
        isLoading = true
        errorMessage = nil
        sources = catalog.visibleSources

        let feed = await catalog.homeFeed()
        guard current == generation else { return }

        var all: [PXCatalogEntry] = []
        var seen = Set<String>()
        for rail in feed {
            for entry in rail.entries where seen.insert(entry.id).inserted {
                all.append(entry)
            }
        }

        if all.isEmpty {
            let fallback = await catalog.items(section: .movies)
            all = fallback.items
            if !fallback.warnings.isEmpty {
                errorMessage = fallback.warnings.first
            }
        }

        var built: [PXHomeRail] = []
        for kind in [PXMediaKind.movie, .series, .anime, .shortDrama] {
            let entries = all.filter { $0.kind == kind }
            guard entries.count >= 3 else { continue }
            built.append(PXHomeRail(
                id: "kind-\(kind.rawValue)",
                title: "\(kind.title)精选",
                subtitle: kindRailSubtitle(kind),
                symbol: kind.symbol,
                style: kind == .anime ? .poster : .landscape,
                entries: Array(entries.prefix(16)),
                seeAllSection: PXCatalogService.section(for: kind)
            ))
        }
        // 站源自己的推荐栏也保留，方便用户感知“内容来自哪里”。
        built.append(contentsOf: feed.prefix(4))

        let heroes = all.prefix(6).map { PXHeroItem(entry: $0) }
        guard current == generation else { return }
        // 先出首屏，再逐个补 TMDB 背景；网络慢时用户仍能立即滚动和点开内容。
        heroItems = heroes
        rails = built
        isLoading = false
        for index in heroItems.indices.prefix(3) {
            guard current == generation else { return }
            let entry = heroItems[index].entry
            if let meta = await metadata.metadata(for: entry.drama) {
                guard current == generation, heroItems.indices.contains(index) else { return }
                heroItems[index] = PXHeroItem(entry: entry, metadata: meta)
            }
        }
    }

    private func kindRailSubtitle(_ kind: PXMediaKind) -> String {
        switch kind {
        case .movie: "来自全部站源的电影"
        case .series: "连续剧 / 网剧 / 英美剧"
        case .anime: "新番 / 国创 / 剧场版"
        case .shortDrama: "竖屏短剧，一划一集"
        default: "持续更新"
        }
    }
}
