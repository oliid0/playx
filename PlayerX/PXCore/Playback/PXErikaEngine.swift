#if canImport(ErikaKit)
import AVFoundation
import ErikaKit
import PlaybackKit
import SwiftUI

/// Erika 内核适配器：FFmpeg 解码 + libass 字幕 + Metal 呈现。对外仍伪装成
/// `PXPlaybackEngine`，因此竖屏 stories / 横屏章节导航 / 弹幕覆盖层完全不受
/// 内核差异影响；只有设置项按 `PXEngineCapability` 增减。
@MainActor
final class PXErikaEngine: PXBasePlaybackEngine {
    override class var kind: PXPlayerEngineKind { .erika }

    private var engine: ErikaEngine?
    private let playerState = PlaybackKit.PlayerState()
    private var consumeTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var tracks: [PlaybackKit.TrackInfo] = []
    private var openTask: Task<Void, Never>?
    private var pendingStart: Double = 0
    private var autoPlay = true
    override var supportsExternalSubtitles: Bool { true }
    var isUsable: Bool { engine != nil }

    override init() {
        super.init()
        do {
            let engine = try ErikaEngine()
            self.engine = engine
            consumeTask = playerState.start(consuming: engine)
            startPolling()
        } catch {
            engine = nil
            publish { $0.state = .failed("Erika 初始化失败：\(error.localizedDescription)") }
        }
    }

    deinit {
        consumeTask?.cancel()
        pollTask?.cancel()
        openTask?.cancel()
    }

    override func makeSurface() -> AnyView {
        engine?.makeSurfaceView() ?? AnyView(Color.black)
    }

    override func load(url: URL, headers: [String: String], startAt: Double, autoplay: Bool) {
        guard let engine else { return }
        pendingStart = startAt
        autoPlay = autoplay
        publish { $0 = .init(); $0.state = .opening }
        // Go 核心的播放地址是本机回环代理，认证头由代理内部附加；把 CDN
        // Referer/UA 再塞给 FFmpeg 会污染对 127.0.0.1 的请求。
        let host = url.host?.lowercased() ?? ""
        let effectiveHeaders = (host == "127.0.0.1" || host == "localhost" || host == "::1") ? [:] : headers
        let source = PlaybackSource(uri: url.absoluteString, headers: effectiveHeaders)
        let volume = snapshot.volume
        openTask?.cancel()
        openTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                // Erika 的 open 同步完成网络连接与格式探测，弱网下可达数十秒；
                // 放到 detached 任务，避免主线程被 open 的锁和网络阻塞。
                try await Task.detached(priority: .userInitiated) {
                    try engine.open(source)
                }.value
                guard !Task.isCancelled else {
                    try? engine.stop()
                    return
                }
                try engine.setVolume(volume)
                if startAt > 0 { try engine.seek(to: .seconds(startAt)) }
                if autoplay { try engine.play() }
            } catch {
                guard !Task.isCancelled else { return }
                self.publish {
                    $0.state = .failed(error.localizedDescription)
                    $0.errorMessage = error.localizedDescription
                }
            }
        }
    }

    override func play() {
        guard let engine else { return }
        try? engine.play()
        publish { $0.state = .playing }
    }

    override func pause() {
        guard let engine else { return }
        try? engine.pause()
        publish { $0.state = .paused }
    }

    override func seek(to seconds: Double) {
        guard let engine else { return }
        try? engine.seek(to: .seconds(max(0, seconds)))
        publish { $0.currentTime = max(0, seconds) }
    }

    override func setRate(_ rate: Double) {
        let value = min(max(rate, 0.25), 3)
        try? engine?.setRate(value)
        publish { $0.rate = value }
    }

    override func setVolume(_ volume: Double) {
        let value = min(max(volume, 0), 1)
        try? engine?.setVolume(value)
        publish { $0.volume = value; $0.isMuted = value < 0.01 }
    }

    override func setMuted(_ muted: Bool) {
        try? engine?.setVolume(muted ? 0 : snapshot.volume)
        publish { $0.isMuted = muted }
    }

    override func stop() {
        consumeTask?.cancel()
        pollTask?.cancel()
        openTask?.cancel()
        try? engine?.stop()
        publish { $0.state = .idle; $0.currentTime = 0 }
    }

    override func selectAudio(_ id: String) {
        guard let track = tracks.first(where: { String($0.id) == id && $0.kind == .audio }) else { return }
        try? engine?.selectAudioTrack(track.id)
        refreshTracks()
    }

    override func selectSubtitle(_ id: String?) {
        if let id, let track = tracks.first(where: { String($0.id) == id && $0.kind == .subtitle }) {
            try? engine?.selectSubtitleTrack(track.id)
        } else {
            try? engine?.selectSubtitleTrack(nil)
        }
        refreshTracks()
    }

    override func setSubtitleScale(_ scale: Double) {
        try? engine?.setSubtitleScale(scale)
    }

    override func setBackgroundPlayback(_ active: Bool) {
        engine?.setBackgroundAudioOnly(active)
    }

    private func startPolling() {
        pollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.pullSnapshot()
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }

    private func pullSnapshot() {
        guard engine != nil else { return }
        let timeline = playerState.timeline
        let duration = Double(timeline.duration.microseconds) / 1_000_000
        let current = Double(timeline.position.microseconds) / 1_000_000
        let state: PXPlaybackState
        switch playerState.state {
        case .idle: state = .idle
        case .opening: state = .opening
        case .ready: state = .ready
        case .playing: state = .playing
        case .paused: state = .paused
        case .stopped: state = .idle
        case .closed: state = .idle
        case .error: state = .failed(playerState.lastError ?? "Erika 播放失败")
        }
        let video = playerState.videoParams
        publish {
            $0.state = state
            $0.currentTime = current
            if duration > 0 { $0.duration = duration }
            if let video {
                $0.videoSize = CGSize(width: video.width, height: video.height)
                $0.isPortraitVideo = video.height > Int(Double(video.width) * 1.04)
            }
        }
        if tracks.isEmpty { refreshTracks() }
    }

    private func refreshTracks() {
        guard let all = try? engine?.tracks() else { return }
        tracks = all
        var audios: [PXPlaybackTrack] = []
        var subtitles: [PXPlaybackTrack] = []
        for track in all {
            switch track.kind {
            case .audio:
                audios.append(.init(
                    id: String(track.id), kind: .audio, title: track.displayTitle,
                    detail: track.language, isSelected: track.selected
                ))
            case .subtitle:
                subtitles.append(.init(
                    id: String(track.id), kind: .subtitle, title: track.displayTitle,
                    detail: track.language, isSelected: track.selected
                ))
            case .video: break
            }
        }
        publish { $0.audioTracks = audios; $0.subtitleTracks = subtitles }
    }
}
#endif
