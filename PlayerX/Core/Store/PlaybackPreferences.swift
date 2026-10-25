import Foundation

/// 播放 / 弹幕 / 下载偏好。只存纯本地、跟账号无关的选项；Go 核心不参与。
/// 用 UserDefaults 即时落盘，设置页改完立刻生效，不需要「保存」按钮。
@MainActor
final class PlaybackPreferences: ObservableObject {
    static let shared = PlaybackPreferences()

    // MARK: - 播放

    @Published var autoPlayNext: Bool {
        didSet { defaults.set(autoPlayNext, forKey: Keys.autoPlayNext) }
    }
    @Published var remembersProgress: Bool {
        didSet { defaults.set(remembersProgress, forKey: Keys.remembersProgress) }
    }
    @Published var preferredRate: Double {
        didSet { defaults.set(preferredRate, forKey: Keys.preferredRate) }
    }
    @Published var preferredQuality: Int {
        didSet { defaults.set(preferredQuality, forKey: Keys.preferredQuality) }
    }
    @Published var backwardSkip: Double {
        didSet { defaults.set(backwardSkip, forKey: Keys.backwardSkip) }
    }
    @Published var forwardSkip: Double {
        didSet { defaults.set(forwardSkip, forKey: Keys.forwardSkip) }
    }
    /// 0 表示常显 HUD。
    @Published var hudAutoHide: Double {
        didSet { defaults.set(hudAutoHide, forKey: Keys.hudAutoHide) }
    }
    @Published var autoPiP: Bool {
        didSet { defaults.set(autoPiP, forKey: Keys.autoPiP) }
    }
    @Published var dragSeekEnabled: Bool {
        didSet { defaults.set(dragSeekEnabled, forKey: Keys.dragSeek) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    // MARK: - 弹幕

    @Published var danmakuByDefault: Bool {
        didSet { defaults.set(danmakuByDefault, forKey: Keys.danmakuByDefault) }
    }
    @Published var danmakuFontSize: Double {
        didSet { defaults.set(danmakuFontSize, forKey: Keys.danmakuFontSize) }
    }
    @Published var danmakuOpacity: Double {
        didSet { defaults.set(danmakuOpacity, forKey: Keys.danmakuOpacity) }
    }
    /// 弹幕穿过屏幕的秒数，越小越快。
    @Published var danmakuSpeed: Double {
        didSet { defaults.set(danmakuSpeed, forKey: Keys.danmakuSpeed) }
    }
    @Published var danmakuTracks: Int {
        didSet { defaults.set(danmakuTracks, forKey: Keys.danmakuTracks) }
    }
    @Published var danmakuShadow: Bool {
        didSet { defaults.set(danmakuShadow, forKey: Keys.danmakuShadow) }
    }

    // MARK: - 下载

    @Published var downloadQuality: Int {
        didSet { defaults.set(downloadQuality, forKey: Keys.downloadQuality) }
    }

    // MARK: - 选项

    static let rates: [Double] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    static let skipOptions: [Double] = [5, 10, 15, 30]
    static let hudAutoHideOptions: [Double] = [0, 2, 4, 6, 8]
    static let qualityOptions: [Int] = [0, 720, 1080, 2160]
    static let danmakuFontOptions: [Double] = [13, 15, 18]
    static let danmakuSpeedOptions: [Double] = [6, 8, 12]
    static let danmakuTrackOptions: [Int] = [2, 4, 5]

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let autoPlayNext = "playerx.playback.autoNext.v1"
        static let remembersProgress = "playerx.playback.remember.v1"
        static let preferredRate = "playerx.playback.rate.v1"
        static let preferredQuality = "playerx.playback.quality.v1"
        static let backwardSkip = "playerx.playback.skipBackward.v1"
        static let forwardSkip = "playerx.playback.skipForward.v1"
        static let hudAutoHide = "playerx.playback.hudAutoHide.v1"
        static let autoPiP = "playerx.playback.autoPiP.v1"
        static let dragSeek = "playerx.playback.dragSeek.v1"
        static let haptics = "playerx.playback.haptics.v1"
        static let danmakuByDefault = "playerx.playback.danmaku.v1"
        static let danmakuFontSize = "playerx.playback.danmaku.font.v1"
        static let danmakuOpacity = "playerx.playback.danmaku.opacity.v1"
        static let danmakuSpeed = "playerx.playback.danmaku.speed.v1"
        static let danmakuTracks = "playerx.playback.danmaku.tracks.v1"
        static let danmakuShadow = "playerx.playback.danmaku.shadow.v1"
        static let downloadQuality = "playerx.download.quality.v1"
    }

    private init() {
        autoPlayNext = defaults.object(forKey: Keys.autoPlayNext) as? Bool ?? true
        remembersProgress = defaults.object(forKey: Keys.remembersProgress) as? Bool ?? true
        preferredRate = defaults.object(forKey: Keys.preferredRate) as? Double ?? 1.0
        preferredQuality = defaults.object(forKey: Keys.preferredQuality) as? Int ?? 0
        backwardSkip = defaults.object(forKey: Keys.backwardSkip) as? Double ?? 10
        forwardSkip = defaults.object(forKey: Keys.forwardSkip) as? Double ?? 10
        hudAutoHide = defaults.object(forKey: Keys.hudAutoHide) as? Double ?? 4
        autoPiP = defaults.object(forKey: Keys.autoPiP) as? Bool ?? true
        dragSeekEnabled = defaults.object(forKey: Keys.dragSeek) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        danmakuByDefault = defaults.object(forKey: Keys.danmakuByDefault) as? Bool ?? true
        danmakuFontSize = defaults.object(forKey: Keys.danmakuFontSize) as? Double ?? 15
        danmakuOpacity = defaults.object(forKey: Keys.danmakuOpacity) as? Double ?? 0.92
        danmakuSpeed = defaults.object(forKey: Keys.danmakuSpeed) as? Double ?? 8
        danmakuTracks = defaults.object(forKey: Keys.danmakuTracks) as? Int ?? 5
        danmakuShadow = defaults.object(forKey: Keys.danmakuShadow) as? Bool ?? true
        downloadQuality = defaults.object(forKey: Keys.downloadQuality) as? Int ?? 0
    }

    /// 防止旧版本写入 1.5x 之外的异常值，播放器初始化时统一校正一次。
    func normalizedRate() -> Double {
        if Self.rates.contains(preferredRate) { return preferredRate }
        return 1.0
    }

    func reset() {
        autoPlayNext = true
        remembersProgress = true
        preferredRate = 1.0
        preferredQuality = 0
        backwardSkip = 10
        forwardSkip = 10
        hudAutoHide = 4
        autoPiP = true
        dragSeekEnabled = true
        hapticsEnabled = true
        danmakuByDefault = true
        danmakuFontSize = 15
        danmakuOpacity = 0.92
        danmakuSpeed = 8
        danmakuTracks = 5
        danmakuShadow = true
        downloadQuality = 0
    }

    static func qualityTitle(_ quality: Int) -> String {
        switch quality {
        case 0: return "自动"
        case 2160: return "4K"
        case 1080: return "1080P"
        case 720: return "720P"
        default: return "\(quality)P"
        }
    }

    static func rateTitle(_ rate: Double) -> String {
        rate == floor(rate) ? "\(Int(rate))x" : "\(rate)x"
    }

    static func skipTitle(_ seconds: Double) -> String {
        "\(Int(seconds)) 秒"
    }

    static func hudAutoHideTitle(_ seconds: Double) -> String {
        seconds <= 0 ? "常显" : "\(Int(seconds)) 秒"
    }

    static func danmakuFontTitle(_ size: Double) -> String {
        switch size {
        case 13: return "小"
        case 18: return "大"
        default: return "标准"
        }
    }

    static func danmakuSpeedTitle(_ seconds: Double) -> String {
        switch seconds {
        case 6: return "快"
        case 12: return "慢"
        default: return "标准"
        }
    }

    static func danmakuTrackTitle(_ tracks: Int) -> String {
        "\(tracks) 行"
    }
}
