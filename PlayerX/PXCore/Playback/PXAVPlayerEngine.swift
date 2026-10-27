import AVFoundation
import SwiftUI

#if os(iOS) || os(tvOS)
import UIKit
import MediaPlayer
#endif

/// 系统 AVPlayer 内核。所有平台可用，也是 macOS 的默认内核。
@MainActor
class PXAVPlayerEngine: PXBasePlaybackEngine {
    override class var kind: PXPlayerEngineKind { .native }

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var audioGroup: AVMediaSelectionGroup?
    private var subtitleGroup: AVMediaSelectionGroup?
    private var audioMap: [String: AVMediaSelectionOption] = [:]
    private var subtitleMap: [String: AVMediaSelectionOption] = [:]
    private var pendingStart: Double = 0
    private var autoPlay = true

    override init() {
        super.init()
        player.actionAtItemEnd = .pause
        installObservers()
        #if os(iOS) || os(tvOS)
        configureAudioSession()
        #endif
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        if let failObserver { NotificationCenter.default.removeObserver(failObserver) }
    }

    override func makeSurface() -> AnyView {
        AnyView(PXAVPlayerSurface(player: player))
    }

    override func load(url: URL, headers: [String: String], startAt: Double, autoplay: Bool) {
        pendingStart = startAt
        autoPlay = autoplay
        var options: [String: Any] = [:]
        if !headers.isEmpty {
            options["AVURLAssetHTTPHeaderFieldsKey"] = headers
        }
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        observe(item: item)
        publish {
            $0 = .init()
            $0.state = .opening
        }
        if startAt > 0 {
            player.seek(to: CMTime(seconds: startAt, preferredTimescale: 600))
        }
        if autoplay {
            play()
        }
    }

    override func play() {
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        player.play()
        player.rate = Float(snapshot.rate)
        publish { $0.state = .playing }
    }

    override func pause() {
        player.pause()
        publish { $0.state = .paused }
    }

    override func seek(to seconds: Double) {
        let time = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        publish { $0.currentTime = max(0, seconds) }
    }

    override func setRate(_ rate: Double) {
        let value = min(max(rate, 0.25), 3)
        publish { $0.rate = value }
        if snapshot.state.isPlaying { player.rate = Float(value) }
    }

    override func setVolume(_ volume: Double) {
        let value = min(max(volume, 0), 1)
        player.volume = Float(value)
        publish { $0.volume = value; $0.isMuted = value < 0.01 }
    }

    override func setMuted(_ muted: Bool) {
        player.isMuted = muted
        publish { $0.isMuted = muted }
    }

    override func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        publish { $0.state = .idle; $0.currentTime = 0 }
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    override func selectAudio(_ id: String) {
        guard let group = audioGroup, let option = audioMap[id] else { return }
        player.currentItem?.select(option, in: group)
        refreshTracks()
    }

    override func selectSubtitle(_ id: String?) {
        guard let group = subtitleGroup else { return }
        if let id, let option = subtitleMap[id] {
            player.currentItem?.select(option, in: group)
        } else {
            player.currentItem?.select(nil, in: group)
        }
        refreshTracks()
    }

    override func setSubtitleScale(_ scale: Double) {
        // AVPlayer 的系统字幕由系统控制，第三方 App 无法直接缩放；保留 API 供 UI 一致。
    }

    private func installObservers() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.refreshSnapshot(time: time)
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.publish { $0.state = .ended; $0.currentTime = $0.duration }
            }
        }
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.publish { $0.state = .playing }
                case .waitingToPlayAtSpecifiedRate:
                    self.publish { $0.state = .buffering }
                case .paused:
                    if self.snapshot.state != .ended, self.snapshot.state != .idle,
                       self.snapshot.state != .failed("") {
                        self.publish { $0.state = .paused }
                    }
                @unknown default: break
                }
            }
        }
    }

    private func observe(item: AVPlayerItem) {
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.publish { $0.state = self.autoPlay ? .playing : .ready }
                    self.loadMediaSelection()
                case .failed:
                    let message = item.error?.localizedDescription ?? "未知错误"
                    self.publish { $0.state = .failed(message); $0.errorMessage = message }
                default: break
                }
            }
        }
        itemStatusObservation = item.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.publish {
                    $0.videoSize = item.presentationSize
                    $0.isPortraitVideo = item.presentationSize.height > item.presentationSize.width * 1.04
                        && item.presentationSize.width > 0
                }
            }
        }
        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] note in
            let message = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription ?? "播放失败"
            Task { @MainActor [weak self] in
                self?.publish { $0.state = .failed(message); $0.errorMessage = message }
            }
        }
    }

    private func refreshSnapshot(time: CMTime) {
        let seconds = time.seconds.isFinite ? max(0, time.seconds) : 0
        let duration = player.currentItem?.duration.seconds ?? 0
        var loaded = 0.0
        if let range = player.currentItem?.loadedTimeRanges.last?.timeRangeValue {
            loaded = (range.start + range.duration).seconds
        }
        let size = player.currentItem?.presentationSize ?? .zero
        let isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        publish {
            $0.currentTime = seconds
            if duration.isFinite, duration > 0 { $0.duration = duration }
            $0.buffered = loaded.isFinite ? loaded : 0
            $0.videoSize = size
            if size.width > 0, size.height > 0 {
                $0.isPortraitVideo = size.height > size.width * 1.04
            }
            if isBuffering, $0.state.isPlaying { $0.state = .buffering }
        }
    }

    private func loadMediaSelection() {
        guard let item = player.currentItem, let asset = item.asset as? AVURLAsset else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let audio = try? await asset.loadMediaSelectionGroup(for: .audible)
            let subtitle = try? await asset.loadMediaSelectionGroup(for: .legible)
            self.audioGroup = audio
            self.subtitleGroup = subtitle
            self.refreshTracks()
        }
    }

    private func refreshTracks() {
        guard let item = player.currentItem else { return }
        audioMap = [:]
        subtitleMap = [:]
        var audio: [PXPlaybackTrack] = []
        var subtitles: [PXPlaybackTrack] = []
        if let group = audioGroup {
            for (index, option) in group.options.enumerated() {
                let id = "audio-\(index)"
                audioMap[id] = option
                audio.append(.init(
                    id: id, kind: .audio,
                    title: option.displayName,
                    detail: option.locale?.identifier,
                    isSelected: item.currentMediaSelection.selectedMediaOption(in: group) == option
                ))
            }
        }
        if let group = subtitleGroup {
            for (index, option) in group.options.enumerated() {
                let id = "subtitle-\(index)"
                subtitleMap[id] = option
                subtitles.append(.init(
                    id: id, kind: .subtitle,
                    title: option.displayName,
                    detail: option.locale?.identifier,
                    isSelected: item.currentMediaSelection.selectedMediaOption(in: group) == option
                ))
            }
        }
        publish {
            $0.audioTracks = audio
            $0.subtitleTracks = subtitles
        }
    }

    private func configureAudioSession() {
        #if os(iOS) || os(tvOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
        #endif
    }
}
