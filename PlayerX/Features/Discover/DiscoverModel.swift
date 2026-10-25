import Foundation

@MainActor
final class DiscoverModel: ObservableObject {
    let provider: ContentProvider

    @Published var categories: [SourceCategory] = []
    @Published var selectedCategoryId: String = ""
    @Published var searchQuery: String = ""
    @Published var items: [Drama] = []
    @Published var isLoadingCategories = false
    @Published var isLoadingPage = false
    @Published var hasMore = true
    @Published var errorMessage: String?
    @Published var warning: String?

    private var page = 1
    private var loadGeneration = 0

    init(provider: ContentProvider) {
        self.provider = provider
    }

    var isInitialLoading: Bool {
        items.isEmpty && isLoadingPage
    }

    var selectedCategoryName: String {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "搜索结果"
        }
        return categories.first(where: { $0.id == selectedCategoryId })?.name ?? "全部"
    }

    func loadCategoriesIfNeeded() async {
        guard categories.isEmpty, !isLoadingCategories else { return }
        isLoadingCategories = true
        defer { isLoadingCategories = false }
        do {
            var loaded = try await provider.categories()
            // Go 侧有的站源会返回空的「全部」项，有的完全不返回；UI 自己补一个，
            // 保证任何站源都能回到「全部」目录。
            if !loaded.contains(where: { $0.id.isEmpty }) {
                loaded.insert(SourceCategory(id: "", name: "全部"), at: 0)
            }
            categories = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCategory(_ id: String) async {
        guard id != selectedCategoryId else { return }
        selectedCategoryId = id
        searchQuery = ""
        await reload(clearImmediately: true)
    }

    func submitSearch() async {
        await reload(clearImmediately: true)
    }

    func clearSearch() async {
        guard !searchQuery.isEmpty else { return }
        searchQuery = ""
        await reload(clearImmediately: true)
    }

    func reload(clearImmediately: Bool = false) async {
        loadGeneration += 1
        let generation = loadGeneration
        page = 1
        hasMore = true
        errorMessage = nil
        warning = nil
        if clearImmediately {
            items = []
        }
        await loadNextPage(generation: generation)
    }

    /// `near` 传即将出现的卡片；离末尾还剩 6 条时提前拉下一页，滚动到底不会停顿。
    func loadMoreIfNeeded(near item: Drama) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if index >= items.count - 6 {
            await loadNextPage(generation: loadGeneration)
        }
    }

    private func loadNextPage(generation: Int) async {
        guard !isLoadingPage, hasMore else { return }
        isLoadingPage = true
        errorMessage = nil
        defer { isLoadingPage = false }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await provider.catalog(
                category: selectedCategoryId,
                page: page,
                query: trimmedQuery.isEmpty ? nil : trimmedQuery
            )
            guard generation == loadGeneration else { return }

            let existingIds = Set(items.map(\.id))
            let newItems = result.items.filter { !existingIds.contains($0.id) }
            if page == 1 {
                items = newItems
            } else {
                items.append(contentsOf: newItems)
            }
            warning = result.warning
            hasMore = result.hasMore && !result.items.isEmpty
            page += 1
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.localizedDescription
        }
    }
}
