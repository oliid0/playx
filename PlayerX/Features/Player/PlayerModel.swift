import AVFoundation
import AVKit
import QuartzCore

#if os(iOS)
import UIKit
import MediaPlayer
import PillarboxPlayer
#else
import AppKit
#endif

/// 播放器状态机。
///
/// 播放内核全部使用 Apple 原生组件：
/// - `AVPlayer` / `AVURLAsset` 负责网络与解码；
/// - `AVPlayerLayer` 负责画面（`NativePlayerSurface.swift`）；
/// - `AVPictureInPictureController` 负责系统画中画；
/// - `AVRoutePickerView` 负责系统 AirPlay 路由选择；
/// - `MPNowPlayingInfoCenter` / `MPRemoteCommandCenter` 负责锁屏与耳机控制。
///
/// HUD 只是控制层，不参与解码。这样既能得到和系统播放器一致的 HLS/字幕/音轨行为，
/// 又能做和 App 一致的界面。
@MainActor
final class PlayerModel: NSObject, ObservableObject {
    struct MediaOption: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String?
    }

    let drama: Drama
    let chapters: [Chapter]
    let provider: ContentProvider

    @Published private(set) var currentIndex: Int
    @Published private(set) var isPlaying = false
    @Published private(set) var isMuted = false
    @Published private(set) var volume: Double = 1
    @Published private(set) var isBuffering = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var bufferedTime: Double = 0
    @Published private(set) var videoSize: CGSize = .zero
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var noticeMessage: String?
    @Published private(set) var isPiPActive = false
    @Published private(set) var isPiPPossible = false
    @Published private(set) var plan: PlaybackPlan?
    @Published private(set) var qualities: [Int] = []
    @Published private(set) var selectedQuality: Int?
    @Published private(set) var danmakuController: DanmakuController?
    @Published private(set) var rate: Double
    @Published var isDanmakuEnabled: Bool

    // AVFoundation 原生媒体选择：HLS / MP4 里带的字幕、CC、备用音轨。
    @Published private(set) var audioOptions: [MediaOption] = []
    @Published private(set) var subtitleOptions: [MediaOption] = []
    @Published private(set) var selectedAudioID: String?
    @Published private(set) var selectedSubtitleID: String?
    @Published private(set) var subtitlesCanBeDisabled = true

    @Published private(set) var showsNextPrompt = false
    @Published private(set) var nextCountdown = 0
    @Published private(set) var sleepTimerMinutes: Int?

    #if os(iOS)
    private let pillarboxPlayer: PillarboxPlayer.Player
    var player: AVPlayer { pillarboxPlayer.systemPlayer }
    #else
    private(set) var player = AVPlayer()
    #endif
    private var playerLayer: AVPlayerLayer?
    private var pipController: AVPictureInPictureController?
    private var pipPossibleObservation: NSKeyValueObservation?
    private var audioSelectionGroup: AVMediaSelectionGroup?
    private var subtitleSelectionGroup: AVMediaSelectionGroup?
    private var audioOptionMap: [String: AVMediaSelectionOption] = [:]
    private var subtitleOptionMap: [String: AVMediaSelectionOption] = [:]

    private var timeObserver: Any?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var presentationSizeObservation: NSKeyValueObservation?
    private var currentItemObservation: NSKeyValueObservation?
    private weak var observedItem: AVPlayerItem?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?

    private var remotePlayTarget: Any?
    private var remotePauseTarget: Any?
    private var remoteToggleTarget: Any?
    private var remoteNextTarget: Any?
    private var remotePreviousTarget: Any?
    private var remoteSeekTarget: Any?

    private var countdownTask: Task<Void, Never>?
    private var sleepTimerTask: Task<Void, Never>?
    private var episodeGeneration = 0
    private var lastSavedAt: TimeInterval = 0
    private var pendingStartAt: Double?
    private var hasStarted = false
    private var didConfigureSession = false
    private var playbackActivity: NSObjectProtocol?

    init(drama: Drama, chapters: [Chapter], provider: ContentProvider, request: PlaybackRequest) {
        self.drama = drama
        self.chapters = chapters
        self.provider = provider
        self.currentIndex = min(max(request.startIndex, 0), max(chapters.count - 1, 0))
        self.rate = PlaybackPreferences.shared.normalizedRate()
        self.isDanmakuEnabled = PlaybackPreferences.shared.danmakuByDefault
        #if os(iOS)
        self.pillarboxPlayer = PillarboxPlayer.Player()
        #endif
        super.init()

        configureAudioSession()
        installTimeObserver()
        observeTimeControlStatus()
        #if os(iOS)
        observeCurrentItem()
        #else
        configureRemoteCommands()
        #endif
        apply(plan: request.plan, startAt: request.startPosition, autoPlay: false)
    }

    // MARK: - 派生信息

    var currentChapter: Chapter? {
        guard chapters.indices.contains(currentIndex) else { return nil }
        return chapters[currentIndex]
    }

    var hasNextEpisode: Bool { currentIndex + 1 < chapters.count }
    var hasPreviousEpisode: Bool { currentIndex > 0 }
    var isPortraitVideo: Bool {
        videoSize.width > 0 && videoSize.height > videoSize.width * 1.05
    }
    var sourceName: String { drama.sourceName }
    var episodeLabel: String { "第 \(currentIndex + 1) 集" }
    var title: String { drama.title }
    var canToggleDanmaku: Bool { danmakuController != nil }
    var hasAudioOptions: Bool { !audioOptions.isEmpty }
    var hasSubtitleOptions: Bool { !subtitleOptions.isEmpty }

    var selectedAudioName: String {
        audioOptions.first(where: { $0.id == selectedAudioID })?.title ?? "默认音轨"
    }

    var selectedSubtitleName: String {
        guard let selectedSubtitleID else { return "关闭" }
        return subtitleOptions.first(where: { $0.id == selectedSubtitleID })?.title ?? "关闭"
    }

    var qualityLabel: String {
        guard let quality = selectedQuality ?? plan?.quality, quality > 0 else { return "自动" }
        if quality >= 2160 { return "4K" }
        if quality >= 1080 { return "1080P" }
        if quality >= 720 { return "720P" }
        return "\(quality)P"
    }

    // MARK: - 生命周期

    func start() {
        guard !hasStarted else {
            startPlayback()
            return
        }
        hasStarted = true
        activateAudioSession()
        #if os(iOS)
        pillarboxPlayer.becomeActive()
        #endif
        startPlayback()
        beginPlaybackActivity()
        updateNowPlayingInfo()
    }

    private func startPlayback() {
        #if os(iOS)
        pillarboxPlayer.playbackSpeed = Float(rate)
        pillarboxPlayer.play()
        #else
        player.playImmediately(atRate: Float(rate))
        #endif
    }

    func stop() {
        saveProgress(force: true)
        cancelNextCountdown()
        clearSleepTimer()
        #if os(iOS)
        pillarboxPlayer.pause()
        pillarboxPlayer.resignActive()
        #else
        player.pause()
        #endif
        danmakuController?.detach()
        danmakuController = nil
        endPlaybackActivity()
        clearNowPlayingInfo()
        removeRemoteCommands()
        deactivateAudioSession()
    }

    // MARK: - 播放控制

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            // 播放到结尾后 AVPlayer 会停在末尾，直接 play() 没有画面，先回到开头。
            if duration > 0, currentTime >= duration - 0.6 {
                seek(to: 0)
            }
            play()
        }
    }

    func play() {
        guard errorMessage == nil else { return }
        activateAudioSession()
        startPlayback()
    }

    func pause() {
        #if os(iOS)
        pillarboxPlayer.pause()
        #else
        player.pause()
        #endif
        saveProgress(force: true)
        updateNowPlayingInfo()
    }

    private var preferredQuality: Int? {
        let value = PlaybackPreferences.shared.preferredQuality
        return value > 0 ? value : nil
    }

    func setVolume(_ value: Double) {
        volume = min(max(value, 0), 1)
        player.volume = Float(volume)
        if volume > 0.01, isMuted {
            isMuted = false
            #if os(iOS)
            pillarboxPlayer.isMuted = false
            #else
            player.isMuted = false
            #endif
        }
    }

    func toggleMute() {
        isMuted.toggle()
        #if os(iOS)
        pillarboxPlayer.isMuted = isMuted
        #else
        player.isMuted = isMuted
        #endif
    }

    func setQuality(_ quality: Int) {
        guard quality > 0, quality != selectedQuality else { return }
        let position = currentTime
        let resumePlaying = isPlaying
        selectedQuality = quality
        Task { await loadEpisode(index: currentIndex, autoPlay: resumePlaying, force: true, quality: quality, startAt: position) }
    }

    func setRate(_ newRate: Double) {
        rate = newRate
        PlaybackPreferences.shared.preferredRate = newRate
        #if os(iOS)
        pillarboxPlayer.playbackSpeed = Float(newRate)
        #else
        if isPlaying {
            player.playImmediately(atRate: Float(newRate))
        }
        #endif
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        guard duration > 0 else { return }
        let clamped = min(max(seconds, 0), max(duration - 0.15, 0))
        #if os(iOS)
        pillarboxPlayer.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        #else
        player.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        #endif
        currentTime = clamped
        updateNowPlayingInfo()
    }

    func skipForward() {
        skip(by: PlaybackPreferences.shared.forwardSkip)
    }

    func skipBackward() {
        skip(by: -PlaybackPreferences.shared.backwardSkip)
    }

    func skip(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    func toggleDanmaku() {
        guard let controller = danmakuController else { return }
        isDanmakuEnabled.toggle()
        controller.isEnabled = isDanmakuEnabled
        PlaybackPreferences.shared.danmakuByDefault = isDanmakuEnabled
    }

    func togglePiP() {
        guard let pipController else { return }
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        }
    }

    func startPiPIfPossible() {
        guard let pipController,
              !pipController.isPictureInPictureActive,
              pipController.isPictureInPicturePossible else { return }
        pipController.startPictureInPicture()
    }

    // MARK: - 选集 / 连播

    func loadEpisode(index: Int, autoPlay: Bool = true, force: Bool = false, quality: Int? = nil, startAt: Double = 0) async {
        guard chapters.indices.contains(index),
              force || index != currentIndex || errorMessage != nil else { return }
        episodeGeneration += 1
        let generation = episodeGeneration

        isLoading = true
        errorMessage = nil
        showsNextPrompt = false
        nextCountdown = 0
        cancelNextCountdown()
        saveProgress(force: true)

        do {
            let chapter = chapters[index]
            let nextPlan: PlaybackPlan
            let localJob = DownloadStore.shared.job(dramaId: drama.id, index: index + 1)
            if localJob?.state == DownloadJob.stateCompleted {
                nextPlan = try await DownloadStore.shared.localPlan(drama: drama, index: index + 1)
            } else {
                nextPlan = try await provider.resolve(
                    drama: drama,
                    chapter: chapter,
                    index: index + 1,
                    quality: quality ?? selectedQuality ?? preferredQuality
                )
            }

            guard generation == episodeGeneration else { return }
            currentIndex = index
            currentTime = startAt
            duration = 0
            apply(plan: nextPlan, startAt: startAt, autoPlay: autoPlay)
            isLoading = false
            if autoPlay {
                activateAudioSession()
                player.playImmediately(atRate: Float(rate))
            }
            updateNowPlayingInfo()
        } catch {
            guard generation == episodeGeneration else { return }
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func playNext() {
        guard hasNextEpisode else { return }
        let next = currentIndex + 1
        cancelNextCountdown()
        Task { await loadEpisode(index: next, autoPlay: true) }
    }

    func playPrevious() {
        guard hasPreviousEpisode else { return }
        cancelNextCountdown()
        Task { await loadEpisode(index: currentIndex - 1, autoPlay: true) }
    }

    func retry() {
        Task { await loadEpisode(index: currentIndex, autoPlay: true, force: true) }
    }

    /// 「重新加载」：同一集也要重新走一遍 resolve（例如线路临时抽风）。
    func reloadCurrentEpisode() {
        Task { await loadEpisode(index: currentIndex, autoPlay: true, force: true) }
    }

    func cancelNextPrompt() {
        showsNextPrompt = false
        nextCountdown = 0
        cancelNextCountdown()
    }

    /// 定时关闭：支持 15 / 30 / 60 分钟；到点暂停并清空。
    func setSleepTimer(minutes: Int?) {
        clearSleepTimer()
        guard let minutes, minutes > 0 else { return }
        sleepTimerMinutes = minutes
        sleepTimerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard !Task.isCancelled, let self else { return }
            self.pause()
            self.sleepTimerMinutes = nil
            self.noticeMessage = "定时关闭已暂停播放"
            self.sleepTimerTask = nil
        }
    }

    func clearSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimerMinutes = nil
    }

    // MARK: - 画面 / PiP 挂载

    func attach(playerLayer: AVPlayerLayer) {
        guard self.playerLayer !== playerLayer else {
            updatePiPPossibility()
            return
        }
        self.playerLayer = playerLayer
        playerLayer.player = player
        updateVideoGravity()

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            isPiPPossible = false
            return
        }
        guard let controller = AVPictureInPictureController(playerLayer: playerLayer) else {
            isPiPPossible = false
            return
        }
        controller.delegate = self
        #if os(iOS)
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        #endif
        pipController = controller
        pipPossibleObservation = controller.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] controller, _ in
            guard let self else { return }
            let possible = controller.isPictureInPicturePossible
            Task { @MainActor [weak self] in
                self?.isPiPPossible = possible
            }
        }
    }

    private func updatePiPPossibility() {
        isPiPPossible = pipController?.isPictureInPicturePossible ?? false
    }

    // MARK: - 字幕 / 音轨

    func selectAudioTrack(id: String) {
        guard let item = player.currentItem,
              let group = audioSelectionGroup,
              let option = audioOptionMap[id] else { return }
        item.select(option, in: group)
        selectedAudioID = id
        updateNowPlayingInfo()
    }

    func selectSubtitleTrack(id: String?) {
        guard let item = player.currentItem, let group = subtitleSelectionGroup else { return }
        if let id {
            guard let option = subtitleOptionMap[id] else { return }
            item.select(option, in: group)
            selectedSubtitleID = id
        } else {
            item.select(nil, in: group)
            selectedSubtitleID = nil
        }
        updateNowPlayingInfo()
    }

    private func refreshMediaOptions(for item: AVPlayerItem) {
        let asset = item.asset
        // iOS 15 / macOS 12 起同步的 mediaSelectionGroup(forMediaCharacteristic:) 已废弃；
        // 统一走 async load，HLS playlist 解析完再安装菜单。
        Task { [weak self] in
            let audio = try? await asset.loadMediaSelectionGroup(for: .audible)
            let subtitles = try? await asset.loadMediaSelectionGroup(for: .legible)
            guard let self, self.player.currentItem === item else { return }
            self.installMediaGroups(audio: audio, subtitles: subtitles, item: item)
        }
    }

    private func installMediaGroups(
        audio: AVMediaSelectionGroup?,
        subtitles: AVMediaSelectionGroup?,
        item: AVPlayerItem
    ) {
        audioSelectionGroup = audio
        subtitleSelectionGroup = subtitles
        subtitlesCanBeDisabled = subtitles?.allowsEmptySelection ?? true

        let audioOptions = makeOptions(from: audio, prefix: "audio")
        self.audioOptions = audioOptions.options
        audioOptionMap = audioOptions.map
        selectedAudioID = selectedID(for: item.currentMediaSelection, group: audio, map: audioOptions.map)

        let subtitleOptions = makeOptions(from: subtitles, prefix: "subtitle")
        self.subtitleOptions = subtitleOptions.options
        subtitleOptionMap = subtitleOptions.map
        selectedSubtitleID = selectedID(for: item.currentMediaSelection, group: subtitles, map: subtitleOptions.map)
    }

    private func makeOptions(
        from group: AVMediaSelectionGroup?,
        prefix: String
    ) -> (options: [MediaOption], map: [String: AVMediaSelectionOption]) {
        guard let group else { return ([], [:]) }
        var map: [String: AVMediaSelectionOption] = [:]
        let options = group.options.enumerated().map { index, option in
            let id = "\(prefix)-\(index)"
            map[id] = option
            let title = option.displayName.isEmpty ? "轨道 \(index + 1)" : option.displayName
            return MediaOption(id: id, title: title, detail: nil)
        }
        return (options, map)
    }

    private func selectedID(
        for selection: AVMediaSelection,
        group: AVMediaSelectionGroup?,
        map: [String: AVMediaSelectionOption]
    ) -> String? {
        guard let group, let selected = selection.selectedMediaOption(in: group) else { return nil }
        return map.first(where: { $0.value.isEqual(selected) })?.key
    }

    // MARK: - AVPlayerItem

    private func apply(plan: PlaybackPlan, startAt: Double, autoPlay: Bool) {
        self.plan = plan
        videoSize = .zero
        let available = (plan.qualities ?? []).filter { $0 > 0 }
        qualities = Array(Set(available)).sorted(by: >)
        selectedQuality = plan.quality
        audioOptions = []
        subtitleOptions = []
        selectedAudioID = nil
        selectedSubtitleID = nil
        audioSelectionGroup = nil
        subtitleSelectionGroup = nil
        audioOptionMap = [:]
        subtitleOptionMap = [:]
        guard let url = URL(string: plan.url) else {
            errorMessage = "播放地址无效"
            return
        }

        #if os(iOS)
        guard let item = PillarboxPlayback.makeItem(drama: drama, chapter: currentChapter, plan: plan) else {
            errorMessage = "播放地址无效"
            return
        }
        pillarboxPlayer.currentItem = item
        // KVO 通常会在 systemPlayer.currentItem 更新时触发；这里再兜底一次，
        // 避免某些 HLS 首帧初始化路径下 KVO 晚到导致时长/字幕菜单为空。
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard let self, let avItem = self.player.currentItem else { return }
            self.observe(item: avItem)
        }
        #else
        let asset: AVURLAsset
        if let headers = plan.headers, !headers.isEmpty {
            asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        } else {
            asset = AVURLAsset(url: url)
        }
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 4
        item.audioTimePitchAlgorithm = .timeDomain
        observe(item: item)
        observeEnd(of: item)
        player.replaceCurrentItem(with: item)
        #endif
        currentTime = startAt
        bufferedTime = 0
        pendingStartAt = startAt > 0 ? startAt : nil

        setupDanmaku(plan: plan)
        if autoPlay {
            activateAudioSession()
            player.playImmediately(atRate: Float(rate))
        }
        updateNowPlayingInfo()
    }

    #if os(iOS)
    /// Pillarbox 自己创建 AVPlayerItem，这里等 systemPlayer.currentItem 出现后再挂 KVO。
    private func observeCurrentItem() {
        currentItemObservation = player.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            Task { @MainActor [weak self] in
                self?.observe(item: item)
            }
        }
    }
    #endif

    private func observe(item: AVPlayerItem) {
        guard observedItem !== item else { return }
        observedItem = item
        presentationSizeObservation = item.observe(\.presentationSize, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            let size = item.presentationSize
            Task { @MainActor [weak self] in
                self?.updateVideoSize(size)
            }
        }
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            let status = item.status
            let failure = item.error?.localizedDescription
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.refreshDuration(from: item)
                    self.refreshMediaOptions(for: item)
                    if let pending = self.pendingStartAt {
                        self.pendingStartAt = nil
                        self.seek(to: pending)
                    }
                    self.updateNowPlayingInfo()
                case .failed:
                    self.isLoading = false
                    self.errorMessage = failure ?? "视频加载失败"
                case .unknown:
                    self.isLoading = true
                @unknown default:
                    break
                }
            }
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }
        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let message = (notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?
                .localizedDescription ?? "播放中断"
            Task { @MainActor [weak self] in
                self?.errorMessage = message
            }
        }
    }

    private func installTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleTick(time)
            }
        }
    }

    private func observeTimeControlStatus() {
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self else { return }
            let playing = player.timeControlStatus == .playing
            let buffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying = playing
                self.isBuffering = buffering
                self.updateNowPlayingInfo()
            }
        }
    }

    private func handleTick(_ time: CMTime) {
        let seconds = time.seconds
        if seconds.isFinite, seconds >= 0 {
            currentTime = seconds
        }
        if let item = player.currentItem {
            refreshDuration(from: item)
            refreshBufferProgress(from: item)
            if item.isPlaybackLikelyToKeepUp == false, player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                isBuffering = true
            }
        }
        isPlaying = player.timeControlStatus == .playing
        saveProgressIfNeeded()
        updateNowPlayingInfo()
    }

    private func refreshDuration(from item: AVPlayerItem) {
        let seconds = item.duration.seconds
        if seconds.isFinite, seconds > 0 {
            duration = seconds
        }
    }

    private func updateVideoSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        videoSize = size
        updateVideoGravity()
    }

    private func updateVideoGravity() {
        guard let playerLayer else { return }
        #if os(iOS)
        if isPortraitVideo {
            playerLayer.videoGravity = Platform.isPad ? .resizeAspect : .resizeAspectFill
        } else {
            playerLayer.videoGravity = .resizeAspect
        }
        #else
        playerLayer.videoGravity = .resizeAspect
        #endif
    }

    private func refreshBufferProgress(from item: AVPlayerItem) {
        guard let range = item.loadedTimeRanges.last?.timeRangeValue else { return }
        let end = CMTimeGetSeconds(CMTimeAdd(range.start, range.duration))
        if end.isFinite, end >= 0 {
            bufferedTime = duration > 0 ? min(end, duration) : end
        }
    }

    private func handlePlaybackEnded() {
        saveProgress(force: true, completed: true)
        isPlaying = false
        guard hasNextEpisode else {
            showsNextPrompt = false
            updateNowPlayingInfo()
            return
        }

        showsNextPrompt = true
        if PlaybackPreferences.shared.autoPlayNext {
            nextCountdown = 5
            countdownTask = Task { [weak self] in
                guard let self else { return }
                for remaining in stride(from: 4, through: 0, by: -1) {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if Task.isCancelled { return }
                    await MainActor.run {
                        self.nextCountdown = remaining
                    }
                }
                if Task.isCancelled { return }
                await self.playNextAfterCountdown()
            }
        }
    }

    private func playNextAfterCountdown() async {
        guard showsNextPrompt, hasNextEpisode else { return }
        showsNextPrompt = false
        nextCountdown = 0
        await loadEpisode(index: currentIndex + 1, autoPlay: true)
    }

    private func cancelNextCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    // MARK: - 进度 / 锁屏

    private func saveProgressIfNeeded() {
        let now = CACurrentMediaTime()
        if now - lastSavedAt >= 5 {
            lastSavedAt = now
            saveProgress(force: false)
        }
    }

    private func saveProgress(force: Bool, completed: Bool = false) {
        guard PlaybackPreferences.shared.remembersProgress,
              duration > 0,
              let chapter = currentChapter else { return }
        let position = completed ? duration : currentTime
        guard position > 1 || completed else { return }
        HistoryStore.shared.record(
            drama: drama,
            chapter: chapter,
            episodeIndex: currentIndex + 1,
            position: min(max(position, 0), duration),
            duration: duration
        )
        if force { lastSavedAt = CACurrentMediaTime() }
    }

    private func updateNowPlayingInfo() {
        // iOS 由 PillarboxPlayer 的 MPNowPlayingSession 接管锁屏 / 控制中心；
        // macOS 仍由 App 自己管理窗口，不需要 Now Playing。
    }

    private func clearNowPlayingInfo() {
        // 同上，交给 Pillarbox 的会话生命周期。
    }

    private func configureRemoteCommands() {
        // Pillarbox 已在 iOS 注册控制中心 / 耳机远程命令，避免重复注册。
    }

    private func removeRemoteCommands() {
        remotePlayTarget = nil
        remotePauseTarget = nil
        remoteToggleTarget = nil
        remoteNextTarget = nil
        remotePreviousTarget = nil
        remoteSeekTarget = nil
    }

    // MARK: - 音频会话 / 常亮

    private func configureAudioSession() {
        #if os(iOS)
        guard !didConfigureSession else { return }
        didConfigureSession = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
        #endif
    }

    private func activateAudioSession() {
        #if os(iOS)
        configureAudioSession()
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func deactivateAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }

    private func beginPlaybackActivity() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #else
        guard playbackActivity == nil else { return }
        playbackActivity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .userInitiated],
            reason: "Playing video"
        )
        #endif
    }

    private func endPlaybackActivity() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #else
        if let playbackActivity {
            ProcessInfo.processInfo.endActivity(playbackActivity)
            self.playbackActivity = nil
        }
        #endif
    }

    // MARK: - 弹幕

    private func setupDanmaku(plan: PlaybackPlan) {
        danmakuController?.detach()
        danmakuController = nil
        guard plan.danmakuId != nil, let session = plan.session else { return }
        let preferences = PlaybackPreferences.shared
        let controller = DanmakuController(playbackSession: session)
        controller.apply(
            fontSize: preferences.danmakuFontSize,
            opacity: preferences.danmakuOpacity,
            speed: preferences.danmakuSpeed,
            tracks: preferences.danmakuTracks,
            shadow: preferences.danmakuShadow
        )
        controller.isEnabled = isDanmakuEnabled
        controller.attach(to: player)
        danmakuController = controller
    }
}

// MARK: - 画中画

extension PlayerModel: AVPictureInPictureControllerDelegate {
    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            self.isPiPActive = true
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor in
            self.isPiPActive = false
            self.updatePiPPossibility()
        }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in
            self.isPiPActive = false
            self.noticeMessage = "画中画启动失败：\(error.localizedDescription)"
        }
    }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
