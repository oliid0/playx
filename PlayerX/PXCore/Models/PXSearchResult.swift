import Foundation

struct PXSearchResult: Identifiable, Hashable {
    enum Source: Hashable {
        case catalog
        case tmdb
        case bangumi
    }

    var id: String
    var source: Source
    var title: String
    var subtitle: String?
    var overview: String?
    var imageURL: URL?
    var badge: String?
    var catalogEntry: PXCatalogEntry?
    var tmdbResult: PXTMDbSearchResult?
    var bangumiResult: PXBangumiSubject?
}
