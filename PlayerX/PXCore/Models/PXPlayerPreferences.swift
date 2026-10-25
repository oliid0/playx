import Foundation
import Combine

/// 播放器专属偏好。与旧的 `PlaybackPreferences` 分开，避免迁移时把已有用户
/// 的短剧设置覆盖掉；切换内核后部分选项会按能力自动隐藏。
@MainActor
final class PXPlayerPreferences: ObservableObject {
    static let shared = PXPlayerPreferences()

    @Published var engine: PXPlayerEngineKind {
        didSet { defaults.set(engine.rawValue, forKey: Keys.engine) }
    }
    @Published var portraitStories: Bool {
        didSet { defaults.set(portraitStories, forKey: Keys.portraitStories) }
    }
    @Published var autoPlayNext: Bool {
        didSet { defaults.set(autoPlayNext, forKey: Keys.autoNext) }
    }
    @Published var autoPlayNextSeconds: Int {
        didSet { defaults.set(autoPlayNextSeconds, forKey: Keys.autoNextSeconds) }
    }
    @Published var rememberProgress: Bool {
        didSet { defaults.set(rememberProgress, forKey: Keys.remember) }
    }
    @Published var preferredRate: Double {
        didSet { defaults.set(preferredRate, forKey: Keys.rate) }
    }
    @Published var forwardSkip: Double {
        didSet { defaults.set(forwardSkip, forKey: Keys.forwardSkip) }
    }
    @Published var backwardSkip: Double {
        didSet { defaults.set(backwardSkip, forKey: Keys.backwardSkip) }
    }
    @Published var controlsAutoHide: Double {
        didSet { defaults.set(controlsAutoHide, forKey: Keys.controlsAutoHide) }
    }
    @Published var dragSeek: Bool {
        didSet { defaults.set(dragSeek, forKey: Keys.dragSeek) }
    }
    @Published var haptics: Bool {
        didSet { defaults.set(haptics, forKey: Keys.haptics) }
    }
    @Published var pipOnBackground: Bool {
        didSet { defaults.set(pipOnBackground, forKey: Keys.pip) }
    }
    @Published var preferHardwareDecode: Bool {
        didSet { defaults.set(preferHardwareDecode, forKey: Keys.hw) }
    }
    @Published var preferredQuality: Int {
        didSet { defaults.set(preferredQuality, forKey: Keys.quality) }
    }
    @Published var subtitleScale: Double {
        didSet { defaults.set(subtitleScale, forKey: Keys.subtitleScale) }
    }
    @Published var danmakuEnabled: Bool {
        didSet { defaults.set(danmakuEnabled, forKey: Keys.danmaku) }
    }
    @Published var danmakuFontSize: Double {
        didSet { defaults.set(danmakuFontSize, forKey: Keys.danmakuFont) }
    }
    @Published var danmakuOpacity: Double {
        didSet { defaults.set(danmakuOpacity, forKey: Keys.danmakuOpacity) }
    }
    @Published var danmakuSpeed: Double {
        didSet { defaults.set(danmakuSpeed, forKey: Keys.danmakuSpeed) }
    }
    @Published var danmakuTracks: Int {
        didSet { defaults.set(danmakuTracks, forKey: Keys.danmakuTracks) }
    }
    @Published var danmakuShadow: Bool {
        didSet { defaults.set(danmakuShadow, forKey: Keys.danmakuShadow) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let engine = "playerx.player.engine.v2"
        static let portraitStories = "playerx.player.portraitStories.v1"
        static let autoNext = "playerx.player.autoNext.v2"
        static let autoNextSeconds = "playerx.player.autoNextSeconds.v1"
        static let remember = "playerx.player.remember.v2"
        static let rate = "playerx.player.rate.v2"
        static let forwardSkip = "playerx.player.forwardSkip.v2"
        static let backwardSkip = "playerx.player.backwardSkip.v2"
        static let controlsAutoHide = "playerx.player.controlsAutoHide.v1"
        static let dragSeek = "playerx.player.dragSeek.v1"
        static let haptics = "playerx.player.haptics.v1"
        static let pip = "playerx.player.pip.v1"
        static let hw = "playerx.player.hardware.v1"
        static let quality = "playerx.player.quality.v2"
        static let subtitleScale = "playerx.player.subtitleScale.v1"
        static let danmaku = "playerx.player.danmaku.v2"
        static let danmakuFont = "playerx.player.danmakuFont.v2"
        static let danmakuOpacity = "playerx.player.danmakuOpacity.v2"
        static let danmakuSpeed = "playerx.player.danmakuSpeed.v2"
        static let danmakuTracks = "playerx.player.danmakuTracks.v2"
        static let danmakuShadow = "playerx.player.danmakuShadow.v2"
    }

    private init() {
        let storedEngine = defaults.string(forKey: Keys.engine).flatMap(PXPlayerEngineKind.init(rawValue:))
        engine = storedEngine?.isAvailable == true ? storedEngine! : .defaultKind
        portraitStories = defaults.object(forKey: Keys.portraitStories) as? Bool ?? true
        autoPlayNext = defaults.object(forKey: Keys.autoNext) as? Bool ?? true
        autoPlayNextSeconds = defaults.object(forKey: Keys.autoNextSeconds) as? Int ?? 8
        rememberProgress = defaults.object(forKey: Keys.remember) as? Bool ?? true
        preferredRate = defaults.object(forKey: Keys.rate) as? Double ?? 1
        forwardSkip = defaults.object(forKey: Keys.forwardSkip) as? Double ?? 10
        backwardSkip = defaults.object(forKey: Keys.backwardSkip) as? Double ?? 10
        controlsAutoHide = defaults.object(forKey: Keys.controlsAutoHide) as? Double ?? 4
        dragSeek = defaults.object(forKey: Keys.dragSeek) as? Bool ?? true
        haptics = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        pipOnBackground = defaults.object(forKey: Keys.pip) as? Bool ?? true
        preferHardwareDecode = defaults.object(forKey: Keys.hw) as? Bool ?? true
        preferredQuality = defaults.object(forKey: Keys.quality) as? Int ?? 0
        subtitleScale = defaults.object(forKey: Keys.subtitleScale) as? Double ?? 1
        danmakuEnabled = defaults.object(forKey: Keys.danmaku) as? Bool ?? true
        danmakuFontSize = defaults.object(forKey: Keys.danmakuFont) as? Double ?? 16
        danmakuOpacity = defaults.object(forKey: Keys.danmakuOpacity) as? Double ?? 0.92
        danmakuSpeed = defaults.object(forKey: Keys.danmakuSpeed) as? Double ?? 8
        danmakuTracks = defaults.object(forKey: Keys.danmakuTracks) as? Int ?? 5
        danmakuShadow = defaults.object(forKey: Keys.danmakuShadow) as? Bool ?? true
    }

    func selectEngine(_ kind: PXPlayerEngineKind) {
        guard kind.isAvailable else { return }
        engine = kind
    }

    var normalizedRate: Double {
        let supported = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        return supported.contains(preferredRate) ? preferredRate : 1
    }

    func reset() {
        engine = .defaultKind
        portraitStories = true
        autoPlayNext = true
        autoPlayNextSeconds = 8
        rememberProgress = true
        preferredRate = 1
        forwardSkip = 10
        backwardSkip = 10
        controlsAutoHide = 4
        dragSeek = true
        haptics = true
        pipOnBackground = true
        preferHardwareDecode = true
        preferredQuality = 0
        subtitleScale = 1
        danmakuEnabled = true
        danmakuFontSize = 16
        danmakuOpacity = 0.92
        danmakuSpeed = 8
        danmakuTracks = 5
        danmakuShadow = true
    }
}
