import Foundation

enum PXTVTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case movies
    case series
    case anime
    case bangumi
    case moviePilot
    case search
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .movies: "电影"
        case .series: "剧集"
        case .anime: "动漫"
        case .bangumi: "追番"
        case .moviePilot: "找片"
        case .search: "搜索"
        case .settings: "设置"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .movies: "film.fill"
        case .series: "tv.fill"
        case .anime: "sparkles.tv.fill"
        case .bangumi: "calendar"
        case .moviePilot: "paperplane.fill"
        case .search: "magnifyingglass"
        case .settings: "gearshape.fill"
        }
    }

    /// tvOS 侧边栏只保留 OcPlayer 同级的五个入口；电影/剧集/动漫由首页 MediaRail 进入，
    /// 不再单独占一级导航。
    static var sidebarTabs: [PXTVTab] { [.home, .bangumi, .moviePilot, .search, .settings] }

    var kind: PXMediaKind? {
        switch self {
        case .movies: .movie
        case .series: .series
        case .anime: .anime
        default: nil
        }
    }
}
