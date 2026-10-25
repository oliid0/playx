import Foundation

struct PXMediaRecommendation: Codable, Identifiable, Hashable, Sendable {
    var tmdbID: Int
    var mediaType: PXMediaKind
    var title: String
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var year: Int?
    var rating: Double?

    var id: String { "\(mediaType.rawValue):\(tmdbID)" }
    var posterURL: URL? { PXImageURL.poster(posterPath, width: 400) }
    var yearText: String? { year.map(String.init) }
}
