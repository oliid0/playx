import Foundation
import Combine

struct PXSearchSourceOption: Identifiable, Hashable {
    let id: String
    let name: String
    let count: Int
}

@MainActor
final class PXSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var scope: PXSearchScope = .all {
        didSet { selectedSourceID = nil }
    }
    @Published private(set) var results: [PXSearchResult] = []
    @Published private(set) var sourceCounts: [String: Int] = [:]
    @Published private(set) var warnings: [String] = []
    @Published var selectedSourceID: String?
    @Published private(set) var isSearching = false
    @Published private(set) var submittedQuery = ""
    @Published private(set) var searchedSourceCount = 0
    @Published var errorMessage: String?

    private var generation = 0
    private let catalog = PXCatalogService.shared
    private let metadata = PXMetadataCoordinator.shared
    private let bangumi = PXBangumiCoordinator.shared
    private var task: Task<Void, Never>?

    var displayedResults: [PXSearchResult] {
        guard let selectedSourceID else { return results }
        return results.filter { $0.sourceID == selectedSourceID }
    }

    var sourceOptions: [PXSearchSourceOption] {
        sourceCounts.compactMap { id, count in
            guard let descriptor = SourceRegistry.descriptor(for: id) else { return nil }
            return PXSearchSourceOption(id: id, name: descriptor.displayName, count: count)
        }
        .sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }

    var totalSourceCount: Int { Set(results.compactMap(\.sourceID)).count }

    func submit() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            sourceCounts = [:]
            warnings = []
            submittedQuery = ""
            return
        }
        task?.cancel()
        generation += 1
        let current = generation
        isSearching = true
        submittedQuery = text
        searchedSourceCount = catalog.searchSources.count
        errorMessage = nil
        results = []
        sourceCounts = [:]
        warnings = []
        selectedSourceID = nil
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            let scope = self.scope
            let catalog = self.catalog
            let metadata = self.metadata
            async let reportTask = catalog.searchReport(query: text, scope: scope)
            async let tmdbTask: [PXTMDbSearchResult] = scope == .sources ? [] : metadata.searchMulti(query: text)
            async let bangumiTask: [PXBangumiSubject] = (scope == .sources || scope == .tmdb)
                ? [] : self.searchBangumi(text)
            let (report, tmdb, bgm) = await (reportTask, tmdbTask, bangumiTask)
            guard current == self.generation, !Task.isCancelled else { return }
            var collected: [PXSearchResult] = []
            for entry in report.entries {
                let descriptor = SourceRegistry.descriptor(for: entry.providerID)
                collected.append(PXSearchResult(
                    id: "catalog-\(entry.id)",
                    source: .catalog,
                    title: entry.drama.title,
                    subtitle: entry.drama.pxDisplaySubtitle,
                    overview: entry.drama.description,
                    imageURL: URL(string: entry.drama.cover ?? ""),
                    badge: descriptor?.displayName ?? "站源",
                    sourceID: entry.providerID,
                    catalogEntry: entry
                ))
            }
            for item in tmdb.prefix(20) {
                collected.append(PXSearchResult(
                    id: "tmdb-\(item.mediaType ?? "x")-\(item.id)",
                    source: .tmdb,
                    title: item.displayTitle,
                    subtitle: item.year.map(String.init),
                    overview: item.overview,
                    imageURL: PXImageURL.poster(item.posterPath, width: 300),
                    badge: item.mediaType == "movie" ? "TMDB 电影" : "TMDB 剧集",
                    sourceID: "tmdb",
                    tmdbResult: item
                ))
            }
            for item in bgm.prefix(20) {
                collected.append(PXSearchResult(
                    id: "bgm-\(item.id)",
                    source: .bangumi,
                    title: item.displayTitle,
                    subtitle: item.episodesText,
                    overview: item.summary,
                    imageURL: item.imageURL,
                    badge: "Bangumi",
                    sourceID: "bangumi",
                    bangumiResult: item
                ))
            }
            self.results = collected
            self.sourceCounts = report.sourceCounts
            self.warnings = report.warnings
            self.isSearching = false
        }
    }

    private func searchBangumi(_ text: String) async -> [PXBangumiSubject] {
        await bangumi.search(text, type: .anime)
        return bangumi.searchResults
    }
}
