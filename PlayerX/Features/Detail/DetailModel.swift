import Foundation

/// 传给播放器的一次播放请求。播放器自己负责续播秒数、后续集数解析和自动连播，
/// Detail 页只负责把「从哪一集开始」和已解析好的第一集 plan 交给它。
struct PlaybackRequest: Identifiable {
    let id = UUID()
    let chapter: Chapter
    let plan: PlaybackPlan
    let playbackSession: String?
    let startIndex: Int
    let startPosition: Double
}

@MainActor
final class DetailModel: ObservableObject {
    let provider: ContentProvider

    @Published var drama: Drama
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var isResolving = false
    @Published var errorMessage: String?
    @Published var warning: String?
    @Published var playback: PlaybackRequest?
    @Published var selectedForDownload: Set<String> = []

    private let history = HistoryStore.shared
    private let downloads = DownloadStore.shared

    init(provider: ContentProvider, drama: Drama) {
        self.provider = provider
        self.drama = drama
    }

    var historyEntry: HistoryEntry? { history.entry(forDramaId: drama.id) }

    /// 续播：有历史记录就接着上次那集放，没有就从第一集开始。
    var resumeChapterIndex: Int {
        guard let entry = historyEntry, chapters.indices.contains(entry.episodeIndex - 1) else { return 1 }
        return entry.episodeIndex
    }

    var resumeChapterIndexZeroBased: Int {
        max(0, resumeChapterIndex - 1)
    }

    var resumeButtonTitle: String {
        guard let entry = historyEntry else { return "立即播放" }
        let progress = entry.remainingSeconds > 0 ? " · \(AppFormat.time(entry.position))" : ""
        return "继续播放 · 第\(resumeChapterIndex)集\(progress)"
    }

    var downloadedCount: Int {
        chapters.enumerated().filter { pair in
            downloads.job(dramaId: drama.id, index: pair.offset + 1)?.state == DownloadJob.stateCompleted
        }.count
    }

    func isDownloaded(_ chapter: Chapter) -> Bool {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return false }
        return downloads.job(dramaId: drama.id, index: index + 1)?.state == DownloadJob.stateCompleted
    }

    func episodeNumber(for chapter: Chapter) -> Int {
        (chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
    }

    func reload() async {
        chapters = []
        errorMessage = nil
        warning = nil
        await loadIfNeeded()
    }

    func loadIfNeeded() async {
        guard chapters.isEmpty, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await provider.detail(for: drama)
            drama = result.drama
            chapters = result.chapters
            warning = result.warning
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resume() async {
        guard chapters.indices.contains(resumeChapterIndexZeroBased) else { return }
        await play(chapter: chapters[resumeChapterIndexZeroBased])
    }

    func play(chapter: Chapter) async {
        guard !isResolving, let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        let episodeIndex = index + 1
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            let plan: PlaybackPlan
            let session: String?
            // 已经下载完成的分集优先播本地文件，不用再联网解析。
            if downloads.job(dramaId: drama.id, index: episodeIndex)?.state == DownloadJob.stateCompleted {
                plan = try await downloads.localPlan(drama: drama, index: episodeIndex)
                session = nil
            } else {
                plan = try await provider.resolve(
                    drama: drama,
                    chapter: chapter,
                    index: episodeIndex,
                    quality: preferredPlaybackQuality
                )
                session = plan.session
            }

            let entry = history.entry(forDramaId: drama.id)
            let shouldResume = PlaybackPreferences.shared.remembersProgress
                && entry?.episodeIndex == episodeIndex
                && (entry?.progress ?? 0) > 0.02
                && (entry?.progress ?? 0) < 0.96
            playback = PlaybackRequest(
                chapter: chapter,
                plan: plan,
                playbackSession: session,
                startIndex: index,
                startPosition: shouldResume ? (entry?.position ?? 0) : 0
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleDownloadSelection(_ chapter: Chapter) {
        if selectedForDownload.contains(chapter.id) {
            selectedForDownload.remove(chapter.id)
        } else {
            selectedForDownload.insert(chapter.id)
        }
    }

    func selectAllForDownload() {
        selectedForDownload = Set(chapters.map(\.id))
    }

    func clearDownloadSelection() {
        selectedForDownload.removeAll()
    }

    func download(chapter: Chapter) async {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        _ = await downloads.enqueue(
            drama: drama,
            episodes: [(chapter, index + 1)],
            quality: preferredDownloadQuality
        )
    }

    func downloadSelected() async {
        let episodes: [(chapter: Chapter, index: Int)] = chapters.enumerated()
            .filter { selectedForDownload.contains($0.element.id) }
            .map { (chapter: $0.element, index: $0.offset + 1) }
        guard !episodes.isEmpty else { return }
        _ = await downloads.enqueue(drama: drama, episodes: episodes, quality: preferredDownloadQuality)
        selectedForDownload.removeAll()
    }

    func downloadAll() async {
        let episodes = chapters.enumerated().map { (chapter: $0.element, index: $0.offset + 1) }
        _ = await downloads.enqueue(drama: drama, episodes: episodes, quality: preferredDownloadQuality)
    }

    private var preferredPlaybackQuality: Int? {
        let value = PlaybackPreferences.shared.preferredQuality
        return value > 0 ? value : nil
    }

    private var preferredDownloadQuality: Int? {
        let value = PlaybackPreferences.shared.downloadQuality
        return value > 0 ? value : nil
    }
}
