import Foundation

/// 一级分区。与 OcPlayer 的“媒体库”对应，但这里把站源直接归一成内容分类，
/// 用户无需先理解某个站源，再进分类。
enum PXCatalogSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case movies
    case series
    case anime
    case shorts
    case variety
    case documentary
    case library
    case bangumi
    case moviepilot
    case downloads
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .movies: "电影"
        case .series: "剧集"
        case .anime: "动漫"
        case .shorts: "短剧"
        case .variety: "综艺"
        case .documentary: "纪录片"
        case .library: "片库"
        case .bangumi: "追番"
        case .moviepilot: "找片"
        case .downloads: "下载"
        case .profile: "我的"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .movies: "film.fill"
        case .series: "tv.fill"
        case .anime: "sparkles.tv.fill"
        case .shorts: "rectangle.portrait.on.rectangle.portrait.fill"
        case .variety: "music.mic"
        case .documentary: "globe.asia.australia.fill"
        case .library: "square.grid.2x2.fill"
        case .bangumi: "calendar"
        case .moviepilot: "paperplane.fill"
        case .downloads: "arrow.down.circle.fill"
        case .profile: "person.crop.circle.fill"
        }
    }

    var mediaKind: PXMediaKind? {
        switch self {
        case .movies: .movie
        case .series: .series
        case .anime: .anime
        case .shorts: .shortDrama
        case .variety: .variety
        case .documentary: .documentary
        default: nil
        }
    }

    static var contentSections: [PXCatalogSection] {
        [.home, .movies, .series, .anime, .shorts, .variety, .documentary]
    }
}
