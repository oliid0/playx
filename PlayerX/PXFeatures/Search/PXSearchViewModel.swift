import Foundation
import Combine

@MainActor
final class PXSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var scope: PXSearchScope = .all
    @Published private(set) var results: [PXSearchResult] = []
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?

    private var generation = 0
    private let catalog = PXCatalogService.shared
    private let metadata = PXMetadataCoordinator.shared
    private let bangumi = PXBangumiCoordinator.shared
    private var task: Task<Void, Never>?

    func submit() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { results = []; return }
        task?.cancel()
        generation += 1
        let current = generation
        isSearching = true
        errorMessage = nil
        results = []
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            async let sourceTask = self.catalog.search(query: text, scope: self.scope)
            async let tmdbTask: [PXTMDbSearchResult] = self.scope == .sources ? [] : self.metadata.searchMulti(query: text)
            async let bangumiTask: [PXBangumiSubject] = (self.scope == .sources || self.scope == .tmdb)
                ? [] : self.searchBangumi(text)
            let (sources, tmdb, bgm) = await (sourceTask, tmdbTask, bangumiTask)
            guard current == self.generation, !Task.isCancelled else { return }
            var collected: [PXSearchResult] = []
            for entry in sources {
                collected.append(PXSearchResult(
                    id: "catalog-\(entry.id)",
                    source: .catalog,
                    title: entry.drama.title,
                    subtitle: entry.drama.pxDisplaySubtitle,
                    overview: entry.drama.description,
                    imageURL: URL(string: entry.drama.cover ?? ""),
                    badge: "站源",
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
                    bangumiResult: item
                ))
            }
            self.results = collected
            self.isSearching = false
        }
    }

    private func searchBangumi(_ text: String) async -> [PXBangumiSubject] {
        await bangumi.search(text, type: .anime)
        return bangumi.searchResults
    }
}
