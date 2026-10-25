import Foundation

enum PXDetailTab: String, CaseIterable, Identifiable {
    case overview
    case episodes
    case cast
    case info

    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview: "概览"
        case .episodes: "剧集"
        case .cast: "演员"
        case .info: "信息"
        }
    }
    var symbol: String {
        switch self {
        case .overview: "text.alignleft"
        case .episodes: "rectangle.stack"
        case .cast: "person.2"
        case .info: "info.circle"
        }
    }
}
