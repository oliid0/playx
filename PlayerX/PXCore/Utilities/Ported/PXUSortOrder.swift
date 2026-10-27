import Foundation

enum PXUSortOrder: String, CaseIterable, Identifiable {
    case latest, rating, title, updated, episodes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .latest: "最近更新"
        case .rating: "评分"
        case .title: "标题"
        case .updated: "更新时间"
        case .episodes: "集数"
        }
    }
}
