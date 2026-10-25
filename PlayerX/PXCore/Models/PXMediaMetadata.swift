import Foundation

/// 详情页叠加的 TMDB 元数据。站源自己的 `Drama` 只提供标题/封面/集数；
/// 年份、类型、评分、简介、演员表、季集标题、预告片都由这一份补全。
struct PXMediaMetadata: Codable, Identifiable, Hashable, Sendable {
    var tmdbID: Int
    var mediaType: PXMediaKind
    var title: String
    var originalTitle: String?
    var overview: String?
    var tagline: String?
    var year: Int?
    var runtimeMinutes: Int?
    var rating: Double?
    var voteCount: Int?
    var popularity: Double?
    var genres: [String]
    var posterPath: String?
    var backdropPath: String?
    var logoPath: String?
    var contentRating: String?
    var status: String?
    var originalLanguage: String?
    var imdbID: String?
    var tvdbID: Int?
    var cast: [PXCastMember]
    var crew: [PXCastMember]
    var seasons: [PXSeasonInfo]
    var videos: [PXVideoClip]
    var recommendations: [PXMediaRecommendation]
    var homepage: String?
    var fetchedAt: Date
    var language: String

    var id: String { "\(mediaType.rawValue):\(tmdbID)" }

    init(
        tmdbID: Int,
        mediaType: PXMediaKind,
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        tagline: String? = nil,
        year: Int? = nil,
        runtimeMinutes: Int? = nil,
        rating: Double? = nil,
        voteCount: Int? = nil,
        popularity: Double? = nil,
        genres: [String] = [],
        posterPath: String? = nil,
        backdropPath: String? = nil,
        logoPath: String? = nil,
        contentRating: String? = nil,
        status: String? = nil,
        originalLanguage: String? = nil,
        imdbID: String? = nil,
        tvdbID: Int? = nil,
        cast: [PXCastMember] = [],
        crew: [PXCastMember] = [],
        seasons: [PXSeasonInfo] = [],
        videos: [PXVideoClip] = [],
        recommendations: [PXMediaRecommendation] = [],
        homepage: String? = nil,
        fetchedAt: Date = Date(),
        language: String = "zh-CN"
    ) {
        self.tmdbID = tmdbID
        self.mediaType = mediaType
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.tagline = tagline
        self.year = year
        self.runtimeMinutes = runtimeMinutes
        self.rating = rating
        self.voteCount = voteCount
        self.popularity = popularity
        self.genres = genres
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.logoPath = logoPath
        self.contentRating = contentRating
        self.status = status
        self.originalLanguage = originalLanguage
        self.imdbID = imdbID
        self.tvdbID = tvdbID
        self.cast = cast
        self.crew = crew
        self.seasons = seasons
        self.videos = videos
        self.recommendations = recommendations
        self.homepage = homepage
        self.fetchedAt = fetchedAt
        self.language = language
    }

    var posterURL: URL? { PXImageURL.poster(posterPath, width: 500) }
    var backdropURL: URL? { PXImageURL.backdrop(backdropPath, width: 1600) }
    var logoURL: URL? { PXImageURL.logo(logoPath, width: 500) }
    var yearText: String? { year.map(String.init) }
    var runtimeText: String? {
        guard let runtimeMinutes, runtimeMinutes > 0 else { return nil }
        return PXFormat.runtime(minutes: runtimeMinutes)
    }
    var ratingText: String? {
        guard let rating, rating > 0 else { return nil }
        return String(format: "%.1f", rating)
    }
    var genreText: String { genres.prefix(3).joined(separator: " · ") }
    var director: PXCastMember? {
        crew.first { $0.job == "Director" || $0.job == "导演" }
    }
    var creators: [PXCastMember] {
        crew.filter { $0.job == "Creator" || $0.job == "导演" || $0.job == "编剧" }
    }
}
