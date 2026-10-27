import Foundation

enum PXUMediaKindLabel {
    static func title(_ kind: PXMediaKind) -> String {
        switch kind {
        case .movie: "电影"
        case .series: "剧集"
        case .anime: "动漫"
        case .shortDrama: "短剧"
        case .variety: "综艺"
        case .documentary: "纪录片"
        }
    }
}
