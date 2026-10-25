import Foundation

enum PXCatalogSort: String, CaseIterable, Identifiable {
    case recommended
    case newest
    case rating
    case title
    case episodes

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

    var symbol: String {
        switch self {
        case .recommended: "sparkles"
        case .newest: "clock"
        case .rating: "star"
        case .title: "textformat.abc"
        case .episodes: "list.number"
        }
    }
}

struct PXCatalogFilter: Equatable {
    var kind: PXMediaKind?
    var sourceID: String?
    var genre: String?
    var year: Int?
    var sort: PXCatalogSort = .recommended

    var isActive: Bool {
        sourceID != nil || genre != nil || year != nil || sort != .recommended
    }

    mutating func reset() {
        sourceID = nil
        genre = nil
        year = nil
        sort = .recommended
    }
}
