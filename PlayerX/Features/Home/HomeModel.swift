import Foundation

/// 首页的一栏内容。数据来自某个站源的第一页目录，失败就整栏消失，不阻塞其它栏。
struct HomeShelf: Identifiable {
    let sourceId: String
    let sourceName: String
    let title: String
    let subtitle: String
    let items: [Drama]

    var id: String { sourceId }
}

struct HomeHeroItem: Identifiable {
    let drama: Drama
    let sourceId: String
    let sourceName: String
    var id: String { drama.id }
}

/// 首页聚合模型。
///
/// 设计取舍：
/// - 不新做「首页接口」，直接把默认可见站源的第一页目录并发拉一遍，按站源拆成栏；
/// - 每栏 12 秒超时：Go 核心的 FFI 调用不能真正取消，但 UI 不能一直转圈；
/// - 任一栏失败只丢这一栏，首页仍然能用（继续观看/站源入口不依赖网络）。
@MainActor
final class HomeModel: ObservableObject {
    @Published private(set) var shelves: [HomeShelf] = []
    @Published private(set) var heroItems: [HomeHeroItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var didLoad = false
    private var generation = 0

    /// 首页只放前三栏，避免一打开 App 同时向 11 个站源发请求。
    private var visibleDescriptors: [SourceDescriptor] {
        let visible = SourceRegistry.all.filter { descriptor in
            descriptor.defaultVisible || SourceLockStore.shared.isUnlockedThisLaunch
        }
        return Array(visible.prefix(3))
    }

    var sources: [SourceDescriptor] {
        SourceRegistry.all.filter { descriptor in
            descriptor.defaultVisible || SourceLockStore.shared.isUnlockedThisLaunch
        }
    }

    var hiddenSourceCount: Int {
        SourceRegistry.all.filter { !$0.defaultVisible }.count
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await reload()
    }

    func reload() async {
        generation += 1
        let currentGeneration = generation
        let descriptors = visibleDescriptors
        guard !descriptors.isEmpty else {
            shelves = []
            heroItems = []
            errorMessage = "没有可用站源"
            return
        }

        isLoading = true
        errorMessage = nil

        var loaded: [String: HomeShelf] = [:]
        await withTaskGroup(of: (String, [Drama]).self) { group in
            for descriptor in descriptors {
                group.addTask {
                    let items = await Self.loadFirstPage(descriptor)
                    return (descriptor.id, items)
                }
            }
            for await (sourceId, items) in group {
                guard currentGeneration == self.generation else { continue }
                guard !items.isEmpty,
                      let descriptor = descriptors.first(where: { $0.id == sourceId }) else { continue }
                let style = SourceVisualStyle.style(for: sourceId)
                loaded[sourceId] = HomeShelf(
                    sourceId: sourceId,
                    sourceName: descriptor.displayName,
                    title: Self.shelfTitle(for: descriptor),
                    subtitle: style.tagline,
                    items: Array(items.prefix(12))
                )
                // 边加载边出栏，用户不用等最慢的站源。
                self.shelves = descriptors.compactMap { loaded[$0.id] }
                if self.heroItems.isEmpty {
                    self.heroItems = Self.makeHeroItems(from: self.shelves)
                }
            }
        }

        guard currentGeneration == generation else { return }
        shelves = descriptors.compactMap { loaded[$0.id] }
        heroItems = Self.makeHeroItems(from: shelves)
        isLoading = false
        if shelves.isEmpty {
            errorMessage = "推荐内容暂时加载失败，下拉重试；站源浏览不受影响"
        }
    }

    nonisolated private static func loadFirstPage(_ descriptor: SourceDescriptor) async -> [Drama] {
        await withTaskGroup(of: [Drama].self) { group in
            group.addTask {
                do {
                    let result = try await descriptor.provider.catalog(category: "", page: 1, query: nil)
                    return result.items
                } catch {
                    return []
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                return []
            }
            let first = await group.next() ?? []
            group.cancelAll()
            return first
        }
    }

    nonisolated private static func shelfTitle(for descriptor: SourceDescriptor) -> String {
        switch descriptor.id {
        case "hongguo": return "红果热播"
        case "hanxiaoquan": return "韩小圈精选"
        case "guipian": return "午夜惊悚场"
        case "sorani": return "青空动漫"
        case "huangdou": return "黄豆片场"
        case "huangju": return "剧果新剧"
        case "yeguo": return "野果推荐"
        case "dsd": return "帝果独播"
        case "huangguoai": return "AI 生成剧场"
        default: return "\(descriptor.displayName)精选"
        }
    }

    nonisolated private static func makeHeroItems(from shelves: [HomeShelf]) -> [HomeHeroItem] {
        guard let first = shelves.first(where: { !$0.items.isEmpty }) else { return [] }
        return first.items.prefix(5).map {
            HomeHeroItem(drama: $0, sourceId: first.sourceId, sourceName: first.sourceName)
        }
    }
}
