import Foundation
import Combine

@MainActor
final class PXTVAppState: ObservableObject {
    @Published var tab: PXTVTab = .home
    @Published var path: [PXTVRoute] = []
    @Published var hero: [PXTVMedia] = []
    @Published var rails: [PXTVRail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var searchResults: [PXTVMedia] = []
    @Published var isSearching = false
    @Published var detail: PXMediaMetadata?
    @Published var detailLoading = false
    @Published var playback: PXTVPlaybackRequest?
    @Published var browseItems: [PXTVMedia] = []
    @Published var browseLoading = false

    let metadata = PXMetadataCoordinator.shared
    let bangumi = PXBangumiCoordinator.shared
    let moviePilot = PXMoviePilotCoordinator.shared
    let settings = PXAppSettings.shared
    let preferences = PXPlayerPreferences.shared

    private var didLoad = false

    func loadHomeIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await reloadHome()
    }

    func reloadHome() async {
        isLoading = true
        errorMessage = nil
        async let trending = metadata.trending()
        async let movies = metadata.discover(kind: .movie)
        async let series = metadata.discover(kind: .series)
        async let anime = metadata.discover(kind: .anime, genreID: 16)
        let (trend, movieItems, seriesItems, animeItems) = await (trending, movies, series, anime)
        var heroItems = trend.prefix(8).map { PXTVMedia(searchResult: $0, fallback: .series) }
        if heroItems.isEmpty {
            heroItems = movieItems.prefix(5).map { PXTVMedia(searchResult: $0, fallback: .movie) }
        }
        hero = Array(heroItems)
        var built: [PXTVRail] = []
        if !movieItems.isEmpty {
            built.append(PXTVRail(id: "movies", title: "热门电影", subtitle: "TMDB 本周趋势", style: .landscape,
                                  items: movieItems.map { PXTVMedia(searchResult: $0, fallback: .movie) }))
        }
        if !seriesItems.isEmpty {
            built.append(PXTVRail(id: "series", title: "热门剧集", subtitle: "正在热播", style: .poster,
                                  items: seriesItems.map { PXTVMedia(searchResult: $0, fallback: .series) }))
        }
        if !animeItems.isEmpty {
            built.append(PXTVRail(id: "anime", title: "动漫精选", subtitle: "Animation / 日本动画", style: .poster,
                                  items: animeItems.map { PXTVMedia(searchResult: $0, fallback: .anime) }))
        }
        if heroItems.isEmpty { errorMessage = "TMDB 暂时不可用，请检查网络或 Token。" }
        rails = built
        isLoading = false
    }

    func loadBrowse(_ tab: PXTVTab) async {
        guard let kind = tab.kind else { return }
        browseLoading = true
        let results = await metadata.discover(kind: kind, genreID: kind == .anime ? 16 : nil)
        browseItems = results.map { PXTVMedia(searchResult: $0, fallback: kind) }
        browseLoading = false
    }

    func loadDetail(_ media: PXTVMedia) async {
        detail = nil
        detailLoading = true
        detail = await metadata.detail(tmdbID: media.tmdbID, kind: media.kind)
        detailLoading = false
    }

    func search() async {
        let text = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { searchResults = []; return }
        isSearching = true
        let results = await metadata.searchMulti(query: text)
        searchResults = results
            .filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
            .map { PXTVMedia(searchResult: $0, fallback: .series) }
        isSearching = false
    }

    func select(_ tab: PXTVTab) {
        self.tab = tab
        path = []
        if let kind = tab.kind {
            Task { await loadBrowse(tab) }
            _ = kind
        }
    }

    func open(_ media: PXTVMedia) {
        path.append(.media(media))
    }

    func playTestStream() {
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8") else { return }
        playback = PXTVPlaybackRequest(url: url, title: "Apple BipBop 测试流", subtitle: "HLS · 多码率")
    }

    func play(urlString: String, title: String) {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "http" || url.scheme == "https" else { return }
        playback = PXTVPlaybackRequest(url: url, title: title, subtitle: url.host)
    }
}
