import Foundation

struct PXTVMedia: Identifiable, Hashable {
    var tmdbID: Int
    var kind: PXMediaKind
    var title: String
    var originalTitle: String?
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var year: Int?
    var rating: Double?

    var id: String { "\(kind.rawValue):\(tmdbID)" }
    var posterURL: URL? { PXImageURL.poster(posterPath, width: 500) }
    var backdropURL: URL? { PXImageURL.backdrop(backdropPath, width: 1600) }
    var yearText: String? { year.map(String.init) }

    init(
        tmdbID: Int,
        kind: PXMediaKind,
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        year: Int? = nil,
        rating: Double? = nil
    ) {
        self.tmdbID = tmdbID
        self.kind = kind
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.year = year
        self.rating = rating
    }

    init(searchResult: PXTMDbSearchResult, fallback: PXMediaKind) {
        let title = searchResult.displayTitle
        self.init(
            tmdbID: searchResult.id,
            kind: searchResult.mediaKind(fallback: fallback),
            title: title,
            originalTitle: searchResult.originalTitle ?? searchResult.originalName,
            overview: searchResult.overview,
            posterPath: searchResult.posterPath,
            backdropPath: searchResult.backdropPath,
            year: searchResult.year,
            rating: searchResult.voteAverage
        )
    }

    init(metadata: PXMediaMetadata) {
        self.init(
            tmdbID: metadata.tmdbID,
            kind: metadata.mediaType,
            title: metadata.title,
            originalTitle: metadata.originalTitle,
            overview: metadata.overview,
            posterPath: metadata.posterPath,
            backdropPath: metadata.backdropPath,
            year: metadata.year,
            rating: metadata.rating
        )
    }
}

struct PXTVRail: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String?
    var style: Style
    var items: [PXTVMedia]

    enum Style: Hashable { case poster, landscape, ranking }
}

struct PXTVPlaybackRequest: Identifiable {
    let id = UUID()
    var url: URL
    var title: String
    var subtitle: String?
}

enum PXTVRoute: Hashable {
    case media(PXTVMedia)
    case bangumi(Int)
    case search
    case settings
}
