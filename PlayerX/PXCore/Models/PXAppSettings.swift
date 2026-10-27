import Foundation
import Combine

/// 集成、元数据与外观设置。凭证都存 UserDefaults，与现有站源设置保持同一
/// 部署模型（未签名/自签安装不会因签名变化而读不到 Keychain）。
@MainActor
final class PXAppSettings: ObservableObject {
    static let shared = PXAppSettings()

    @Published var tmdbEnabled: Bool { didSet { defaults.set(tmdbEnabled, forKey: Keys.tmdbEnabled) } }
    @Published var tmdbLanguage: String { didSet { defaults.set(tmdbLanguage, forKey: Keys.tmdbLanguage) } }
    @Published var tmdbToken: String { didSet { defaults.set(tmdbToken, forKey: Keys.tmdbToken) } }
    @Published var autoMatchMetadata: Bool { didSet { defaults.set(autoMatchMetadata, forKey: Keys.autoMatch) } }

    @Published var danmakuGateway: String { didSet { defaults.set(danmakuGateway, forKey: Keys.danmakuGateway) } }
    @Published var danmakuAPIKey: String { didSet { defaults.set(danmakuAPIKey, forKey: Keys.danmakuAPIKey) } }
    @Published var danmakuAutoMatch: Bool { didSet { defaults.set(danmakuAutoMatch, forKey: Keys.danmakuAuto) } }

    @Published var bangumiEnabled: Bool { didSet { defaults.set(bangumiEnabled, forKey: Keys.bangumiEnabled) } }
    @Published var bangumiAccessToken: String { didSet { defaults.set(bangumiAccessToken, forKey: Keys.bangumiToken) } }
    @Published var bangumiUsername: String { didSet { defaults.set(bangumiUsername, forKey: Keys.bangumiUser) } }
    @Published var bangumiPreferChinese: Bool { didSet { defaults.set(bangumiPreferChinese, forKey: Keys.bangumiChinese) } }

    @Published var moviePilotEnabled: Bool { didSet { defaults.set(moviePilotEnabled, forKey: Keys.mpEnabled) } }
    @Published var moviePilotURL: String { didSet { defaults.set(moviePilotURL, forKey: Keys.mpURL) } }
    @Published var moviePilotUsername: String { didSet { defaults.set(moviePilotUsername, forKey: Keys.mpUser) } }
    @Published var moviePilotPassword: String { didSet { defaults.set(moviePilotPassword, forKey: Keys.mpPassword) } }
    @Published var moviePilotToken: String { didSet { defaults.set(moviePilotToken, forKey: Keys.mpToken) } }

    @Published var customUserAgent: String { didSet { defaults.set(customUserAgent, forKey: Keys.userAgent) } }
    @Published var showAdultContent: Bool { didSet { defaults.set(showAdultContent, forKey: Keys.adult) } }
    @Published var preferredSourceIDs: [String] { didSet { defaults.set(preferredSourceIDs, forKey: Keys.sources) } }

    private let defaults = UserDefaults.standard

    static let builtInTMDbToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OGE5ZTJmYWM3YmE1NDU5ZDdiOTFiYTZmYTQ4MjQ2NyIsIm5iZiI6MTc5MjkzOTA0OC44NzAwMDAxLCJzdWIiOiI2YWRlMTQyODBhMjM2M2Q0YzExNzIxNGYiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.XzKOmm7EvJdCvRDZzKDy6wPhUeZzgoAZJHV-4unktZU"

    static let builtInDanmakuGateway = "https://dandanplay.3841625.xyz"
    static let builtInDanmakuKey = "ocp_-zNBxWgtukt0JD7sjQQgzcNk99MUrERqGlg6rABKFQQ"

    private enum Keys {
        static let tmdbEnabled = "playerx.settings.tmdb.enabled.v1"
        static let tmdbLanguage = "playerx.settings.tmdb.language.v1"
        static let tmdbToken = "playerx.settings.tmdb.token.v1"
        static let autoMatch = "playerx.settings.tmdb.autoMatch.v1"
        static let danmakuGateway = "playerx.settings.danmaku.gateway.v1"
        static let danmakuAPIKey = "playerx.settings.danmaku.key.v1"
        static let danmakuAuto = "playerx.settings.danmaku.auto.v1"
        static let bangumiEnabled = "playerx.settings.bangumi.enabled.v1"
        static let bangumiToken = "playerx.settings.bangumi.token.v1"
        static let bangumiUser = "playerx.settings.bangumi.user.v1"
        static let bangumiChinese = "playerx.settings.bangumi.chinese.v1"
        static let mpEnabled = "playerx.settings.moviepilot.enabled.v1"
        static let mpURL = "playerx.settings.moviepilot.url.v1"
        static let mpUser = "playerx.settings.moviepilot.user.v1"
        static let mpPassword = "playerx.settings.moviepilot.password.v1"
        static let mpToken = "playerx.settings.moviepilot.token.v1"
        static let userAgent = "playerx.settings.network.userAgent.v1"
        static let adult = "playerx.settings.content.adult.v1"
        static let sources = "playerx.settings.sources.v1"
    }

    private init() {
        tmdbEnabled = defaults.object(forKey: Keys.tmdbEnabled) as? Bool ?? true
        tmdbLanguage = defaults.string(forKey: Keys.tmdbLanguage) ?? "zh-CN"
        tmdbToken = defaults.string(forKey: Keys.tmdbToken) ?? Self.builtInTMDbToken
        autoMatchMetadata = defaults.object(forKey: Keys.autoMatch) as? Bool ?? true
        danmakuGateway = defaults.string(forKey: Keys.danmakuGateway) ?? Self.builtInDanmakuGateway
        danmakuAPIKey = defaults.string(forKey: Keys.danmakuAPIKey) ?? Self.builtInDanmakuKey
        danmakuAutoMatch = defaults.object(forKey: Keys.danmakuAuto) as? Bool ?? true
        bangumiEnabled = defaults.object(forKey: Keys.bangumiEnabled) as? Bool ?? true
        bangumiAccessToken = defaults.string(forKey: Keys.bangumiToken) ?? ""
        bangumiUsername = defaults.string(forKey: Keys.bangumiUser) ?? ""
        bangumiPreferChinese = defaults.object(forKey: Keys.bangumiChinese) as? Bool ?? true
        moviePilotEnabled = defaults.object(forKey: Keys.mpEnabled) as? Bool ?? true
        moviePilotURL = defaults.string(forKey: Keys.mpURL) ?? ""
        moviePilotUsername = defaults.string(forKey: Keys.mpUser) ?? ""
        moviePilotPassword = defaults.string(forKey: Keys.mpPassword) ?? ""
        moviePilotToken = defaults.string(forKey: Keys.mpToken) ?? ""
        customUserAgent = defaults.string(forKey: Keys.userAgent) ?? ""
        showAdultContent = defaults.object(forKey: Keys.adult) as? Bool ?? false
        preferredSourceIDs = defaults.stringArray(forKey: Keys.sources) ?? []
    }

    var effectiveTMDbToken: String {
        let value = tmdbToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? Self.builtInTMDbToken : value
    }

    var effectiveDanmakuGateway: URL? {
        URL(string: danmakuGateway.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var effectiveDanmakuKey: String {
        let value = danmakuAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? Self.builtInDanmakuKey : value
    }

    var effectiveMoviePilotURL: URL? {
        let raw = moviePilotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let url = URL(string: raw), url.scheme != nil { return url }
        return URL(string: "https://\(raw)")
    }
}
