import Foundation
import Combine

/// 首页数据面，按 OcPlayer 的四个栏目组织：
/// 继续观看 / 接下来看 / 最近添加 / 媒体库。
/// 这里不再造“电影 / 剧集 / 动漫”一级 Tab——每个站源或外部源就是一个媒体库，
/// 用户从首页进入库，再在库内按分类浏览。
@MainActor
final class PXHomeViewModel: ObservableObject {
    @Published private(set) var latest: [PXCatalogEntry] = []
    @Published private(set) var libraries: [SourceDescriptor] = []
    @Published private(set) var libraryCovers: [String: [Drama]] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let catalog: PXCatalogService
    private var didLoad = false
    private var generation = 0

    init(catalog: PXCatalogService = .shared) {
        self.catalog = catalog
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
        libraries = catalog.visibleSources

        let feed = await catalog.homeFeed()
        guard current == generation else { return }

        var entries: [PXCatalogEntry] = []
        var seen = Set<String>()
        var covers: [String: [Drama]] = [:]
        for rail in feed {
            let sourceID = rail.id.replacingOccurrences(of: "source-", with: "")
            for entry in rail.entries {
                if seen.insert(entry.id).inserted { entries.append(entry) }
                if entry.drama.cover?.isEmpty == false, (covers[sourceID]?.count ?? 0) < 4 {
                    covers[sourceID, default: []].append(entry.drama)
                }
            }
        }
        if entries.isEmpty {
            let fallback = await catalog.items(section: .library)
            entries = fallback.items
            if !fallback.warnings.isEmpty { errorMessage = fallback.warnings.first }
        }
        libraryCovers = covers
        latest = Array(entries.prefix(30))
        if libraries.isEmpty {
            errorMessage = "没有可用的媒体库，请到设置中添加站源或媒体源。"
        }
        isLoading = false
    }
}
