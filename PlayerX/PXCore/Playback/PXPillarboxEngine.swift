#if canImport(PillarboxPlayer)
import AVFoundation
import PillarboxPlayer
import SwiftUI

#if os(iOS) || os(tvOS)
import UIKit
#endif

/// 默认内核。Pillarbox 负责队列、系统控制中心、画中画与 AirPlay；HUD 仍是
/// 我们自己的 SwiftUI 层，所以竖屏 stories 与横屏章节导航可以完全复用。
@MainActor
final class PXPillarboxEngine: PXBasePlaybackEngine {
    override class var kind: PXPlayerEngineKind { .pillarbox }

    private let player: PillarboxPlayer.Player
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var timeControlObservation: NSKeyValueObservation?
    private var statusObservation: NSKeyValueObservation?
    private var audioGroup: AVMediaSelectionGroup?
    private var subtitleGroup: AVMediaSelectionGroup?
    private var audioMap: [String: AVMediaSelectionOption] = [:]
    private var subtitleMap: [String: AVMediaSelectionOption] = [:]
    private var autoPlay = true

    override init() {
        self.player = PillarboxPlayer.Player()
        super.init()
        installObservers()
    }

    deinit {
        if let timeObserver { player.systemPlayer.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    override func makeSurface() -> AnyView {
        AnyView(
            VideoView(player: player)
                .supportsPictureInPicture(true)
                .gravity(.resizeAspect)
        )
    }

    override func load(url: URL, headers: [String: String], startAt: Double, autoplay: Bool) {
        autoPlay = autoplay
        player.currentItem = .simple(url: url)
        player.becomeActive()
        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        publish { $0 = .init(); $0.state = .opening }
        if startAt > 0 {
            player.seek(to: CMTime(seconds: startAt, preferredTimescale: 600))
        }
        if autoplay { play() }
    }

    override func play() {
        player.play()
        publish { $0.state = .playing }
    }

    override func pause() {
        player.pause()
        publish { $0.state = .paused }
    }

    override func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: max(0, seconds), preferredTimescale: 600))
        publish { $0.currentTime = max(0, seconds) }
    }

    override func setRate(_ rate: Double) {
        let value = min(max(rate, 0.25), 3)
        player.systemPlayer.defaultRate = Float(value)
        if player.shouldPlay { player.systemPlayer.rate = Float(value) }
        publish { $0.rate = value }
    }

    override func setVolume(_ volume: Double) {
        let value = min(max(volume, 0), 1)
        player.systemPlayer.volume = Float(value)
        publish { $0.volume = value; $0.isMuted = value < 0.01 }
    }

    override func setMuted(_ muted: Bool) {
        player.isMuted = muted
        publish { $0.isMuted = muted }
    }

    override func stop() {
        player.pause()
        player.resignActive()
        player.currentItem = nil
        publish { $0.state = .idle; $0.currentTime = 0 }
    }

    override func selectAudio(_ id: String) {
        guard let item = player.systemPlayer.currentItem,
              let group = audioGroup, let option = audioMap[id] else { return }
        item.select(option, in: group)
        refreshTracks()
    }

    override func selectSubtitle(_ id: String?) {
        guard let item = player.systemPlayer.currentItem, let group = subtitleGroup else { return }
        if let id, let option = subtitleMap[id] {
            item.select(option, in: group)
        } else {
            item.select(nil, in: group)
        }
        refreshTracks()
    }

    private func installObservers() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.systemPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in self?.refresh(time: time) }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.publish { $0.state = .ended; $0.currentTime = $0.duration }
            }
        }
        timeControlObservation = player.systemPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch player.timeControlStatus {
                case .playing: self.publish { $0.state = .playing }
                case .waitingToPlayAtSpecifiedRate: self.publish { $0.state = .buffering }
                case .paused: if self.snapshot.state.isPlaying || self.snapshot.state == .buffering {
                    self.publish { $0.state = .paused }
                }
                @unknown default: break
                }
            }
        }
        statusObservation = player.systemPlayer.observe(\.currentItem?.status, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if player.currentItem?.status == .readyToPlay {
                    self.publish { $0.state = self.autoPlay ? .playing : .ready }
                    self.loadTracks()
                } else if player.currentItem?.status == .failed {
                    let message = player.currentItem?.error?.localizedDescription ?? "播放失败"
                    self.publish { $0.state = .failed(message); $0.errorMessage = message }
                }
            }
        }
    }

    private func refresh(time: CMTime) {
        let current = time.seconds.isFinite ? max(0, time.seconds) : 0
        let duration = player.systemPlayer.currentItem?.duration.seconds ?? 0
        var loaded = 0.0
        if let range = player.systemPlayer.currentItem?.loadedTimeRanges.last?.timeRangeValue {
            loaded = (range.start + range.duration).seconds
        }
        let size = player.systemPlayer.currentItem?.presentationSize ?? .zero
        publish {
            $0.currentTime = current
            if duration.isFinite, duration > 0 { $0.duration = duration }
            $0.buffered = loaded.isFinite ? loaded : 0
            $0.videoSize = size
            if size.width > 0, size.height > 0 { $0.isPortraitVideo = size.height > size.width * 1.04 }
        }
    }

    private func loadTracks() {
        guard let asset = player.systemPlayer.currentItem?.asset as? AVURLAsset else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.audioGroup = try? await asset.loadMediaSelectionGroup(for: .audible)
            self.subtitleGroup = try? await asset.loadMediaSelectionGroup(for: .legible)
            self.refreshTracks()
        }
    }

    private func refreshTracks() {
        guard let item = player.systemPlayer.currentItem else { return }
        audioMap = [:]
        subtitleMap = [:]
        var audios: [PXPlaybackTrack] = []
        var subtitles: [PXPlaybackTrack] = []
        if let group = audioGroup {
            for (index, option) in group.options.enumerated() {
                let id = "audio-\(index)"
                audioMap[id] = option
                audios.append(.init(
                    id: id, kind: .audio, title: option.displayName,
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
                    id: id, kind: .subtitle, title: option.displayName,
                    detail: option.locale?.identifier,
                    isSelected: item.currentMediaSelection.selectedMediaOption(in: group) == option
                ))
            }
        }
        publish { $0.audioTracks = audios; $0.subtitleTracks = subtitles }
    }
}
#endif
