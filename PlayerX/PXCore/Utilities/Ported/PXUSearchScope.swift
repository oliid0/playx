import Foundation

enum PXUSearchScope: String, CaseIterable, Identifiable {
    case all, station, external, tmdb, bangumi
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "全部"
        case .station: "站源"
        case .external: "媒体库"
        case .tmdb: "TMDB"
        case .bangumi: "Bangumi"
        }
    }
}
