import Foundation
import Combine

@MainActor
final class PXBrowseViewModel: ObservableObject {
    @Published private(set) var items: [PXCatalogEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?
    @Published var filter = PXCatalogFilter()
    @Published private(set) var categories: [SourceCategory] = []
    @Published var selectedCategory: String = ""
    @Published private(set) var warnings: [String] = []

    let section: PXCatalogSection
    let initialSourceID: String?
    private var page = 1
    private var generation = 0
    private let catalog = PXCatalogService.shared

    init(section: PXCatalogSection, initialSource: String? = nil) {
        self.section = section
        self.initialSourceID = initialSource
        self.filter.kind = section.mediaKind
        self.filter.sourceID = initialSource
    }

    var title: String {
        if let initialSourceID, let descriptor = SourceRegistry.descriptor(for: initialSourceID) {
            return descriptor.displayName
        }
        return section == .library ? "片库" : section.title
    }

    var subtitle: String {
        let count = items.count
        if let kind = filter.kind { return "\(kind.title) · \(count) 部" }
        return "\(count) 部内容"
    }

    func load(reset: Bool = true) async {
        if reset {
            generation += 1
            page = 1
            isLoading = true
            items = []
        } else {
            guard hasMore, !isLoadingMore else { return }
            isLoadingMore = true
            page += 1
        }
        let current = generation
        defer {
            if reset { isLoading = false } else { isLoadingMore = false }
        }

        let result: PXCatalogService.Page
        if let sourceID = filter.sourceID,
           let descriptor = SourceRegistry.descriptor(for: sourceID),
           section == .library || initialSourceID != nil || !selectedCategory.isEmpty {
            result = await loadFromSingleSource(descriptor)
        } else {
            result = await catalog.items(
                section: section,
                page: page,
                filter: filter
            )
        }
        guard current == generation else { return }
        if reset {
            items = result.items
        } else {
            let existing = Set(items.map(\.id))
            items.append(contentsOf: result.items.filter { !existing.contains($0.id) })
            if result.items.isEmpty { page = max(1, page - 1) }
        }
        hasMore = result.hasMore && result.items.count > 0
        warnings = result.warnings
        errorMessage = result.warnings.first
        if reset {
            await loadCategoriesIfNeeded()
        }
    }

    func reload() async {
        await load(reset: true)
    }

    func loadMoreIfNeeded(current: PXCatalogEntry) async {
        guard let index = items.firstIndex(of: current), index >= items.count - 6 else { return }
        await load(reset: false)
    }

    func selectCategory(_ id: String) async {
        selectedCategory = id
        await load(reset: true)
    }

    func apply(_ newFilter: PXCatalogFilter) async {
        filter = newFilter
        selectedCategory = ""
        await load(reset: true)
    }

    private func loadCategoriesIfNeeded() async {
        guard categories.isEmpty else { return }
        let descriptors: [SourceDescriptor]
        if let sourceID = filter.sourceID, let descriptor = SourceRegistry.descriptor(for: sourceID) {
            descriptors = [descriptor]
        } else {
            descriptors = Array(catalog.visibleSources.prefix(3))
        }
        var result: [SourceCategory] = []
        var seen = Set<String>()
        for descriptor in descriptors {
            for category in await catalog.categories(for: descriptor) {
                if seen.insert(category.id).inserted { result.append(category) }
            }
        }
        categories = result
    }

    private func loadFromSingleSource(_ descriptor: SourceDescriptor) async -> PXCatalogService.Page {
        do {
            let category = selectedCategory
            let response = try await descriptor.provider.catalog(
                category: category,
                page: page,
                query: nil
            )
            let entries = response.items.compactMap { drama -> PXCatalogEntry? in
                guard drama.source == descriptor.id else { return nil }
                return PXCatalogEntry(drama: drama, section: section, providerID: descriptor.id)
            }
            return PXCatalogService.Page(
                items: entries,
                hasMore: response.hasMore,
                warnings: response.warning.map { [$0] } ?? []
            )
        } catch {
            return PXCatalogService.Page(items: [], hasMore: false, warnings: [error.localizedDescription])
        }
    }
}
