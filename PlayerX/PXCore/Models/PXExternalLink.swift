import Foundation

struct PXExternalLink: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var subtitle: String?
    var url: URL
    var symbol: String

    static func make(imdbID: String?, tmdbID: Int, mediaType: PXMediaKind, homepage: String?) -> [PXExternalLink] {
        var links: [PXExternalLink] = []
        if let imdbID, let url = URL(string: "https://www.imdb.com/title/\(imdbID)/") {
            links.append(.init(title: "IMDb", subtitle: imdbID, url: url, symbol: "film"))
        }
        var path = mediaType == .movie ? "movie" : "tv"
        if mediaType == .anime { path = "tv" }
        if let url = URL(string: "https://www.themoviedb.org/\(path)/\(tmdbID)") {
            links.append(.init(title: "TMDB", subtitle: nil, url: url, symbol: "star.square"))
        }
        if let homepage, let url = URL(string: homepage) {
            links.append(.init(title: "官方网站", subtitle: nil, url: url, symbol: "safari"))
        }
        return links
    }
}
