import Foundation
struct PXDiagnosticsSummary {
    var appVersion: String
    var system: String
    var device: String
    var engine: String
    var tmdbConfigured: Bool
    var bangumiConfigured: Bool
    var moviePilotConfigured: Bool
    var danmakuConfigured: Bool
    var text: String {
        [
            "PlayerX \(appVersion)",
            "设备：\(device) · \(system)",
            "内核：\(engine)",
            "TMDB：\(tmdbConfigured ? "已配置" : "未配置")",
            "Bangumi：\(bangumiConfigured ? "已配置" : "未配置")",
            "MoviePilot：\(moviePilotConfigured ? "已配置" : "未配置")",
            "弹幕：\(danmakuConfigured ? "已配置" : "未配置")",
        ].joined(separator: "\n")
    }
}
