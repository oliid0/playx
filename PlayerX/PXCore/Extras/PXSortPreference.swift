import Foundation
enum PXSortPreference: String, CaseIterable, Identifiable {
    case recommended, newest, rating, title, episodes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .recommended: "推荐"
        case .newest: "最新"
        case .rating: "评分"
        case .title: "标题"
        case .episodes: "集数"
        }
    }
}
