import Foundation

enum PXSearchScope: String, CaseIterable, Identifiable {
    case all
    case sources
    case tmdb
    case bangumi

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "全部"
        case .sources: "站源"
        case .tmdb: "TMDB"
        case .bangumi: "Bangumi"
        }
    }
}
