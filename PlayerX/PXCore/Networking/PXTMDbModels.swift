import Foundation

struct PXTMDbGenre: Decodable, Hashable, Sendable {
    var id: Int
    var name: String
}

struct PXTMDbBelongsToCollection: Decodable, Hashable, Sendable {
    var id: Int
    var name: String?
    var posterPath: String?
    var backdropPath: String?
}

struct PXTMDbExternalIDs: Decodable, Hashable, Sendable {
    var imdbId: String?
    var tvdbId: Int?
    var facebookId: String?
    var instagramId: String?
    var twitterId: String?
}

struct PXTMDbCastDTO: Decodable, Hashable, Sendable {
    var id: Int
    var name: String
    var character: String?
    var profilePath: String?
    var order: Int?
}

struct PXTMDbCrewDTO: Decodable, Hashable, Sendable {
    var id: Int
    var name: String
    var job: String?
    var department: String?
    var profilePath: String?
}

struct PXTMDbCredits: Decodable, Hashable, Sendable {
    var cast: [PXTMDbCastDTO]?
    var crew: [PXTMDbCrewDTO]?
}

struct PXTMDbImage: Decodable, Hashable, Sendable {
    var filePath: String?
    var iso6391: String?
    var width: Int?
    var height: Int?
    var voteAverage: Double?
}

struct PXTMDbImages: Decodable, Hashable, Sendable {
    var logos: [PXTMDbImage]?
    var posters: [PXTMDbImage]?
    var backdrops: [PXTMDbImage]?
}

struct PXTMDbContentRating: Decodable, Hashable, Sendable {
    var iso31661: String?
    var rating: String?
}

struct PXTMDbContentRatings: Decodable, Hashable, Sendable {
    var results: [PXTMDbContentRating]?
}

struct PXTMDbReleaseDate: Decodable, Hashable, Sendable {
    var certification: String?
    var releaseDate: String?
}

struct PXTMDbReleaseDateCountry: Decodable, Hashable, Sendable {
    var iso31661: String?
    var releaseDates: [PXTMDbReleaseDate]?
}

struct PXTMDbReleaseDates: Decodable, Hashable, Sendable {
    var results: [PXTMDbReleaseDateCountry]?
}

struct PXTMDbVideoDTO: Decodable, Hashable, Sendable {
    var id: String?
    var key: String?
    var name: String?
    var site: String?
    var type: String?
    var official: Bool?
}

struct PXTMDbVideos: Decodable, Hashable, Sendable {
    var results: [PXTMDbVideoDTO]?
}

struct PXTMDbSeasonSummary: Decodable, Hashable, Sendable {
    var id: Int?
    var seasonNumber: Int?
    var name: String?
    var overview: String?
    var posterPath: String?
    var airDate: String?
    var episodeCount: Int?
}

struct PXTMDbEpisodeDTO: Decodable, Hashable, Sendable {
    var id: Int?
    var episodeNumber: Int?
    var seasonNumber: Int?
    var name: String?
    var overview: String?
    var stillPath: String?
    var airDate: String?
    var runtime: Int?
    var voteAverage: Double?
}

struct PXTMDbSeasonDetail: Decodable, Hashable, Sendable {
    var id: Int?
    var seasonNumber: Int?
    var name: String?
    var overview: String?
    var posterPath: String?
    var airDate: String?
    var episodes: [PXTMDbEpisodeDTO]?
}

struct PXTMDbSearchResult: Decodable, Hashable, Sendable {
    var id: Int
    var mediaType: String?
    var title: String?
    var name: String?
    var originalTitle: String?
    var originalName: String?
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: String?
    var firstAirDate: String?
    var voteAverage: Double?
    var voteCount: Int?
    var popularity: Double?
    var originalLanguage: String?
    var genreIDs: [Int]?

    var displayTitle: String { title ?? name ?? originalTitle ?? originalName ?? "" }
    var dateText: String? { releaseDate ?? firstAirDate }

    func mediaKind(fallback: PXMediaKind) -> PXMediaKind {
        if fallback == .anime { return .anime }
        switch mediaType {
        case "movie": return .movie
        case "tv": return fallback == .anime ? .anime : .series
        default: return fallback
        }
    }

    var year: Int? { PXFormat.date(dateText).map { Calendar.current.component(.year, from: $0) } }
}

struct PXTMDbSearchResponse: Decodable, Sendable {
    var page: Int?
    var results: [PXTMDbSearchResult]?
    var totalPages: Int?
    var totalResults: Int?
}

struct PXTMDbRecommendationDTO: Decodable, Hashable, Sendable {
    var id: Int
    var mediaType: String?
    var title: String?
    var name: String?
    var overview: String?
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: String?
    var firstAirDate: String?
    var voteAverage: Double?
}

struct PXTMDbRecommendationList: Decodable, Hashable, Sendable {
    var page: Int?
    var results: [PXTMDbRecommendationDTO]?
    var totalPages: Int?
}

struct PXTMDbDetailDTO: Decodable, Sendable {
    var id: Int
    var title: String?
    var name: String?
    var originalTitle: String?
    var originalName: String?
    var overview: String?
    var tagline: String?
    var releaseDate: String?
    var firstAirDate: String?
    var runtime: Int?
    var episodeRunTime: [Int]?
    var voteAverage: Double?
    var voteCount: Int?
    var popularity: Double?
    var genres: [PXTMDbGenre]?
    var posterPath: String?
    var backdropPath: String?
    var homepage: String?
    var status: String?
    var originalLanguage: String?
    var belongsToCollection: PXTMDbBelongsToCollection?
    var images: PXTMDbImages?
    var credits: PXTMDbCredits?
    var contentRatings: PXTMDbContentRatings?
    var releaseDates: PXTMDbReleaseDates?
    var externalIds: PXTMDbExternalIDs?
    var seasons: [PXTMDbSeasonSummary]?
    var videos: PXTMDbVideos?
    var recommendations: PXTMDbRecommendationList?
    var similar: PXTMDbRecommendationList?
}
