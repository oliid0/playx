import Foundation
import Combine
import SwiftUI
import AVFoundation

@MainActor
final class PXPlayerModel: ObservableObject {
    let request: PXPlaybackRequest
    @Published private(set) var snapshot = PXPlayerSnapshot()
    @Published private(set) var engineKind: PXPlayerEngineKind
    @Published private(set) var currentIndex: Int
    @Published private(set) var plan: PlaybackPlan
    @Published private(set) var chapters: [Chapter]
    @Published private(set) var metadata: PXMediaMetadata?
    @Published private(set) var isResolving = false
    @Published private(set) var showsNextPrompt = false
    @Published private(set) var nextCountdown = 0
    @Published var isDanmakuEnabled: Bool
    @Published var controlsVisible = true
    @Published var isLocked = false
    @Published var notice: String?

    let danmaku = PXDanmakuCoordinator()
    private(set) var engine: (any PXPlaybackEngine)?
    private let history = HistoryStore.shared
    private let preferences = PXPlayerPreferences.shared
    private var nextTask: Task<Void, Never>?
    private var hideTask: Task<Void, Never>?
    private var hasStarted = false
    private var lastSavedAt = Date.distantPast
    private var currentRate: Double

    init(request: PXPlaybackRequest) {
        self.request = request
        self.chapters = request.chapters
        self.plan = request.plan
        self.metadata = request.metadata
        self.currentIndex = min(max(request.startIndex, 0), max(request.chapters.count - 1, 0))
        self.currentRate = PXPlayerPreferences.shared.normalizedRate
        self.isDanmakuEnabled = PXPlayerPreferences.shared.danmakuEnabled
        let preferred = request.preferredEngine ?? PXPlayerPreferences.shared.engine
        self.engineKind = preferred.isAvailable ? preferred : .native
        installEngine(kind: engineKind, startAt: request.startPosition, autoplay: false, loadNow: false)
    }

    var currentChapter: Chapter? {
        chapters.indices.contains(currentIndex) ? chapters[currentIndex] : nil
    }

    var title: String { metadata?.title ?? request.drama.title }
    var episodeText: String { "第 \(currentIndex + 1) 集 / \(chapters.count) 集" }
    var hasNext: Bool { currentIndex + 1 < chapters.count }
    var hasPrevious: Bool { currentIndex > 0 }
    var duration: Double { max(snapshot.duration, 0) }
    var currentTime: Double { min(max(snapshot.currentTime, 0), max(snapshot.duration, 0.01)) }
    var progress: Double { duration > 0 ? currentTime / duration : 0 }
    var isPortraitVideo: Bool { snapshot.isPortraitVideo || request.drama.pxKind == .shortDrama }
    var selectedQuality: Int { plan.quality ?? request.preferredQuality ?? 0 }
    var qualityLabel: String {
        selectedQuality > 0 ? PXFormat.quality(selectedQuality) : "自动"
    }
    var danmakuCount: Int { danmaku.comments.count }

    var availableRates: [Double] { [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2] }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        activateAudio()
        engine?.load(
            url: URL(string: plan.url) ?? URL(string: "about:blank")!,
            headers: plan.headers ?? [:],
            startAt: request.startPosition,
            autoplay: true
        )
        engine?.setRate(currentRate)
        loadDanmaku()
        scheduleHide()
    }

    func stop() {
        nextTask?.cancel()
        hideTask?.cancel()
        saveProgress(force: true)
        engine?.stop()
        engine?.onChange = nil
        engine = nil
        danmaku.clear()
        deactivateAudio()
    }

    func togglePlayPause() {
        revealsControls()
        if snapshot.state.isPlaying || snapshot.state == .buffering {
            engine?.pause()
        } else if snapshot.state == .ended {
            engine?.seek(to: 0)
            engine?.play()
        } else {
            engine?.play()
        }
    }

    func play() {
        engine?.play()
        scheduleHide()
    }

    func pause() {
        engine?.pause()
        saveProgress(force: true)
    }

    func seek(to seconds: Double) {
        engine?.seek(to: min(max(seconds, 0), max(duration - 0.1, 0)))
    }

    func skip(_ delta: Double) {
        seek(to: currentTime + delta)
        PXHaptics.light()
    }

    func skipBackward() { skip(-preferences.backwardSkip) }
    func skipForward() { skip(preferences.forwardSkip) }

    func setRate(_ rate: Double) {
        currentRate = rate
        preferences.preferredRate = rate
        engine?.setRate(rate)
        notice = String(format: "%.2fx", rate)
    }

    func cycleRate() {
        guard let index = availableRates.firstIndex(of: currentRate) else {
            setRate(1); return
        }
        setRate(availableRates[(index + 1) % availableRates.count])
    }

    func toggleMute() {
        engine?.setMuted(!snapshot.isMuted)
    }

    func setVolume(_ value: Double) {
        engine?.setVolume(value)
    }

    func toggleDanmaku() {
        isDanmakuEnabled.toggle()
        preferences.danmakuEnabled = isDanmakuEnabled
    }

    func playNext() {
        guard hasNext else { return }
        Task { await loadEpisode(index: currentIndex + 1) }
    }

    func playPrevious() {
        guard hasPrevious else { return }
        Task { await loadEpisode(index: currentIndex - 1) }
    }

    func dismissNextPrompt() {
        nextTask?.cancel()
        showsNextPrompt = false
    }

    func playEpisode(_ index: Int) {
        Task { await loadEpisode(index: index) }
    }

    func retry() {
        Task { await loadEpisode(index: currentIndex) }
    }

    func loadEpisode(index: Int) async {
        guard chapters.indices.contains(index), !isResolving else { return }
        isResolving = true
        nextTask?.cancel()
        showsNextPrompt = false
        defer { isResolving = false }
        do {
            let chapter = chapters[index]
            let downloads = DownloadStore.shared
            let resolved: PlaybackPlan
            if downloads.job(dramaId: request.drama.id, index: index + 1)?.state == DownloadJob.stateCompleted {
                resolved = try await downloads.localPlan(drama: request.drama, index: index + 1)
            } else {
                resolved = try await request.provider.resolve(
                    drama: request.drama,
                    chapter: chapter,
                    index: index + 1,
                    quality: selectedQuality > 0 ? selectedQuality : nil
                )
            }
            saveProgress(force: true)
            engine?.stop()
            plan = resolved
            currentIndex = index
            installEngine(kind: engineKind, startAt: 0, autoplay: true)
            loadDanmaku()
        } catch {
            notice = error.localizedDescription
            snapshot.state = .failed(error.localizedDescription)
            snapshot.errorMessage = error.localizedDescription
        }
    }

    func changeQuality(_ quality: Int) async {
        guard quality != selectedQuality else { return }
        isResolving = true
        defer { isResolving = false }
        do {
            let chapter = currentChapter ?? request.chapter
            let resolved = try await request.provider.resolve(
                drama: request.drama, chapter: chapter,
                index: currentIndex + 1, quality: quality > 0 ? quality : nil
            )
            let position = currentTime
            plan = resolved
            installEngine(kind: engineKind, startAt: position, autoplay: true)
            preferences.preferredQuality = quality
        } catch {
            notice = error.localizedDescription
        }
    }

    func switchEngine(_ kind: PXPlayerEngineKind) {
        guard kind.isAvailable, kind != engineKind else { return }
        let position = currentTime
        let wasPlaying = snapshot.state.isPlaying || snapshot.state == .buffering
        saveProgress(force: true)
        engine?.stop()
        engineKind = kind
        preferences.engine = kind
        installEngine(kind: kind, startAt: position, autoplay: wasPlaying)
    }

    func selectAudio(_ track: PXPlaybackTrack) {
        engine?.selectAudio(track.id)
    }

    func selectSubtitle(_ track: PXPlaybackTrack?) {
        engine?.selectSubtitle(track?.id)
    }

    func setSubtitleScale(_ value: Double) {
        preferences.subtitleScale = value
        engine?.setSubtitleScale(value)
    }

    func toggleLock() {
        isLocked.toggle()
        if isLocked { controlsVisible = false }
        else { revealsControls() }
    }

    func revealsControls() {
        guard !isLocked else { return }
        withAnimation(PXTheme.quick) { controlsVisible = true }
        scheduleHide()
    }

    func hideControls() {
        guard !isLocked, snapshot.state.isPlaying else { return }
        withAnimation(PXTheme.quick) { controlsVisible = false }
    }

    func scheduleHide() {
        hideTask?.cancel()
        let seconds = preferences.controlsAutoHide
        guard seconds > 0, snapshot.state.isPlaying, !isLocked else { return }
        hideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.hideControls()
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        #if os(iOS)
        if phase == .background {
            if preferences.pipOnBackground {
                // Pillarbox 的 VideoView 自带 PiP；原生内核没有自动 PiP，保留播放。
            }
            saveProgress(force: true)
        }
        #endif
    }

    private func installEngine(kind: PXPlayerEngineKind, startAt: Double, autoplay: Bool, loadNow: Bool = true) {
        guard let engine = PXPlaybackEngineFactory.resolve(kind) else { return }
        self.engine = engine
        engineKind = engine.kind
        engine.onChange = { [weak self] snapshot in
            guard let self else { return }
            let previousState = self.snapshot.state
            self.snapshot = snapshot
            if snapshot.state == .ended, previousState != .ended {
                self.handleEnded()
            }
            if snapshot.state.isPlaying, !previousState.isPlaying {
                self.activateAudio()
                self.scheduleHide()
            }
            self.saveProgress(force: false)
        }
        engine.setVolume(snapshot.volume)
        if loadNow {
            engine.load(
                url: URL(string: plan.url) ?? URL(string: "about:blank")!,
                headers: plan.headers ?? [:],
                startAt: startAt,
                autoplay: autoplay
            )
            engine.setRate(currentRate)
        }
    }

    private func handleEnded() {
        saveProgress(force: true)
        guard preferences.autoPlayNext, hasNext else {
            showsNextPrompt = false
            return
        }
        showsNextPrompt = true
        nextCountdown = preferences.autoPlayNextSeconds
        nextTask?.cancel()
        nextTask = Task { @MainActor [weak self] in
            while let self, self.nextCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self.nextCountdown -= 1
            }
            guard !Task.isCancelled else { return }
            self?.playNext()
        }
    }

    private func loadDanmaku() {
        danmaku.clear()
        guard preferences.danmakuEnabled else { return }
        danmaku.load(
            title: title,
            episodeNumber: currentIndex + 1,
            dramaID: request.drama.id
        )
    }

    private func saveProgress(force: Bool) {
        guard preferences.rememberProgress, snapshot.duration > 1, snapshot.currentTime > 2 else { return }
        guard force || Date().timeIntervalSince(lastSavedAt) > 4 else { return }
        lastSavedAt = Date()
        guard let chapter = currentChapter else { return }
        history.record(
            drama: request.drama,
            chapter: chapter,
            episodeIndex: currentIndex + 1,
            position: snapshot.currentTime,
            duration: snapshot.duration
        )
    }

    private func activateAudio() {
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func deactivateAudio() {
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
