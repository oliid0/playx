import Foundation
import Combine

@MainActor
final class PXDetailViewModel: ObservableObject {
    let entry: PXCatalogEntry
    let provider: ContentProvider

    @Published private(set) var drama: Drama
    @Published private(set) var chapters: [Chapter] = []
    @Published private(set) var metadata: PXMediaMetadata?
    @Published private(set) var seasons: [PXSeasonInfo] = []
    @Published private(set) var selectedSeason = 1
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMetadata = false
    @Published private(set) var isResolving = false
    @Published var errorMessage: String?
    @Published var warning: String?
    @Published var tab: PXDetailTab = .overview
    @Published var selectedChapter: Int = 0
    @Published var descriptionExpanded = false
    @Published var showMatchSheet = false
    @Published var playback: PXPlaybackRequest?
    @Published private(set) var selectedQuality: Int

    private let history = HistoryStore.shared
    private let downloads = DownloadStore.shared
    private let follow = FollowStore.shared
    private let metaCoordinator = PXMetadataCoordinator.shared
    private let settings = PXAppSettings.shared
    private let preferences = PXPlayerPreferences.shared
    private var didLoad = false

    init(entry: PXCatalogEntry, provider: ContentProvider? = nil, resume: HistoryEntry? = nil) {
        self.entry = entry
        self.drama = entry.drama
        self.provider = provider ?? entry.provider ?? SourceRegistry.all[0].provider
        self.selectedQuality = PXPlayerPreferences.shared.preferredQuality
        if let resume {
            selectedChapter = max(0, resume.episodeIndex - 1)
        }
    }

    var title: String { metadata?.title ?? drama.title }
    var subtitle: String? { metadata?.originalTitle }
    var overview: String? { metadata?.overview ?? drama.description }
    var yearText: String? { metadata?.yearText ?? drama.pxYear.map(String.init) }
    var rating: Double? { metadata?.rating }
    var genres: [String] { metadata?.genres.isEmpty == false ? metadata!.genres : drama.pxGenres }
    var runtimeText: String? { metadata?.runtimeText }
    var contentRating: String? { metadata?.contentRating }
    var cast: [PXCastMember] { metadata?.cast ?? [] }
    var crew: [PXCastMember] { metadata?.crew ?? [] }
    var recommendations: [PXMediaRecommendation] { metadata?.recommendations ?? [] }
    var videos: [PXVideoClip] { metadata?.videos ?? [] }
    var posterURL: URL? { metadata?.posterURL ?? URL(string: drama.cover ?? "") }
    var backdropURL: URL? { metadata?.backdropURL ?? URL(string: drama.cover ?? "") }
    var logoURL: URL? { metadata?.logoURL }

    var currentSeason: PXSeasonInfo? {
        seasons.first { $0.seasonNumber == selectedSeason } ?? seasons.first
    }

    var currentMetadataEpisodes: [PXEpisodeInfo] {
        currentSeason?.episodes ?? []
    }

    var followStatus: FollowStatus? { follow.status(forDramaId: drama.id) }

    var historyEntry: HistoryEntry? { history.entry(forDramaId: drama.id) }

    var resumeIndex: Int {
        guard let entry = historyEntry,
              chapters.indices.contains(max(0, entry.episodeIndex - 1)) else { return 0 }
        return max(0, entry.episodeIndex - 1)
    }

    var resumePosition: Double {
        guard let entry = historyEntry, entry.episodeIndex == resumeIndex + 1,
              preferences.rememberProgress, entry.progress > 0.02, entry.progress < 0.96 else { return 0 }
        return entry.position
    }

    var resumeTitle: String {
        if historyEntry == nil { return "立即播放" }
        return "继续播放 · 第 \(resumeIndex + 1) 集"
    }

    var mediaInfo: PXMediaTechnicalInfo {
        PXMediaTechnicalInfo.from(plan: nil, chapter: chapters.indices.contains(selectedChapter) ? chapters[selectedChapter] : nil)
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        async let detailTask: DetailResult? = {
            do { return try await provider.detail(for: drama) }
            catch { return nil }
        }()
        async let metadataTask: PXMediaMetadata? = metaCoordinator.metadata(for: drama)

        let detail = await detailTask
        if let detail {
            drama = detail.drama
            chapters = detail.chapters
            warning = detail.warning
            selectedChapter = min(resumeIndex, max(chapters.count - 1, 0))
        } else {
            errorMessage = "详情加载失败，请检查站源网络。"
        }

        let meta = await metadataTask
        apply(metadata: meta)
        isLoading = false
        if let meta, meta.seasons.count > 1 {
            await loadSeason(meta.seasons.first(where: { $0.seasonNumber > 0 })?.seasonNumber ?? meta.seasons[0].seasonNumber)
        }
    }

    func reloadMetadata() async {
        isLoadingMetadata = true
        defer { isLoadingMetadata = false }
        let fresh = await metaCoordinator.refresh(drama: drama, metadata: metadata)
            ?? await metaCoordinator.metadata(for: drama)
        apply(metadata: fresh)
    }

    func selectSeason(_ number: Int) async {
        selectedSeason = number
        await loadSeason(number)
    }

    func loadSeason(_ number: Int) async {
        guard let metadata, metadata.mediaType != .movie else { return }
        isLoadingMetadata = true
        defer { isLoadingMetadata = false }
        guard let season = await metaCoordinator.season(tvID: metadata.tmdbID, seasonNumber: number) else { return }
        if let index = seasons.firstIndex(where: { $0.seasonNumber == number }) {
            seasons[index] = season
        } else {
            seasons.append(season)
        }
    }

    func play(index: Int? = nil, resume: Bool = false) async {
        guard !chapters.isEmpty, !isResolving else { return }
        let target = min(max(index ?? selectedChapter, 0), chapters.count - 1)
        selectedChapter = target
        isResolving = true
        defer { isResolving = false }
        do {
            let episodeIndex = target + 1
            let plan: PlaybackPlan
            if downloads.job(dramaId: drama.id, index: episodeIndex)?.state == DownloadJob.stateCompleted {
                plan = try await downloads.localPlan(drama: drama, index: episodeIndex)
            } else {
                plan = try await provider.resolve(
                    drama: drama,
                    chapter: chapters[target],
                    index: episodeIndex,
                    quality: selectedQuality > 0 ? selectedQuality : nil
                )
            }
            let start = (resume || target == resumeIndex) ? resumePosition : 0
            playback = PXPlaybackRequest(
                drama: drama,
                chapters: chapters,
                provider: provider,
                chapter: chapters[target],
                plan: plan,
                startIndex: target,
                startPosition: start,
                metadata: metadata,
                preferredEngine: preferences.engine,
                preferredQuality: selectedQuality
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resume() async {
        await play(index: resumeIndex, resume: true)
    }

    func selectChapter(_ index: Int) {
        selectedChapter = min(max(index, 0), max(chapters.count - 1, 0))
    }

    func toggleFollow() {
        if followStatus == nil {
            follow.setStatus(.watching, for: drama)
        } else if followStatus == .watching {
            follow.setStatus(.watched, for: drama)
        } else {
            follow.remove(dramaId: drama.id)
        }
    }

    func downloadCurrent() async {
        guard chapters.indices.contains(selectedChapter) else { return }
        _ = await downloads.enqueue(
            drama: drama,
            episodes: [(chapters[selectedChapter], selectedChapter + 1)],
            quality: selectedQuality > 0 ? selectedQuality : nil
        )
    }

    func downloadAll() async {
        let episodes = chapters.enumerated().map { ($0.element, $0.offset + 1) }
        _ = await downloads.enqueue(drama: drama, episodes: episodes,
                                    quality: selectedQuality > 0 ? selectedQuality : nil)
    }

    func isDownloaded(_ index: Int) -> Bool {
        downloads.job(dramaId: drama.id, index: index + 1)?.state == DownloadJob.stateCompleted
    }

    func downloadProgress(_ index: Int) -> Double {
        downloads.job(dramaId: drama.id, index: index + 1)?.progress ?? 0
    }

    func manuallyMatch(_ result: PXTMDbSearchResult) async {
        isLoadingMetadata = true
        defer { isLoadingMetadata = false }
        if let meta = await metaCoordinator.manuallyMatch(drama: drama, result: result, kind: drama.pxKind) {
            apply(metadata: meta)
        }
    }

    func clearMatch() async {
        await metaCoordinator.clearMatch(drama: drama)
        metadata = nil
        seasons = []
    }

    func searchMetadata(_ query: String) async -> [PXTMDbSearchResult] {
        await metaCoordinator.search(query: query, kind: drama.pxKind, year: drama.pxYear)
    }

    func openBangumi() -> PXBangumiSubject? {
        nil
    }

    private func apply(metadata: PXMediaMetadata?) {
        self.metadata = metadata
        seasons = metadata?.seasons.filter { $0.seasonNumber > 0 } ?? []
        if let first = seasons.first(where: { ($0.episodeCount ?? 0) > 0 }) ?? seasons.first {
            selectedSeason = first.seasonNumber
        }
    }
}
