import Foundation

/// 媒体类型。站源是“加了 Emby/Jellyfin 之后的分类”，本枚举就是用户看到的
/// 电影 / 剧集 / 动漫 / 短剧 / 综艺 / 纪录片六类；分类页、详情页和 TMDB 匹配
/// 全部以它为准，而不是零散地判断 `Drama.category` 字符串。
enum PXMediaKind: String, CaseIterable, Codable, Identifiable, Hashable, Sendable {
    case movie
    case series
    case anime
    case shortDrama
    case variety
    case documentary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .movie: "电影"
        case .series: "剧集"
        case .anime: "动漫"
        case .shortDrama: "短剧"
        case .variety: "综艺"
        case .documentary: "纪录片"
        }
    }

    var pluralTitle: String { title }

    var symbol: String {
        switch self {
        case .movie: "film.fill"
        case .series: "tv.fill"
        case .anime: "sparkles.tv.fill"
        case .shortDrama: "rectangle.portrait.on.rectangle.portrait.fill"
        case .variety: "music.mic"
        case .documentary: "globe.asia.australia.fill"
        }
    }

    /// TMDB 只有 movie / tv 两个顶层端点；动漫与剧集共用 tv。
    var tmdbMediaType: String {
        switch self {
        case .movie: "movie"
        default: "tv"
        }
    }

    var isEpisodic: Bool {
        switch self {
        case .movie: false
        default: true
        }
    }
}
