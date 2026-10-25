import Foundation

struct PXSeasonInfo: Codable, Identifiable, Hashable, Sendable {
    var seasonNumber: Int
    var name: String?
    var overview: String?
    var posterPath: String?
    var airDate: String?
    var episodeCount: Int?
    var episodes: [PXEpisodeInfo]

    var id: Int { seasonNumber }

    init(
        seasonNumber: Int,
        name: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: String? = nil,
        episodeCount: Int? = nil,
        episodes: [PXEpisodeInfo] = []
    ) {
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.episodes = episodes
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return seasonNumber == 0 ? "特别篇" : "第 \(seasonNumber) 季"
    }

    var posterURL: URL? {
        PXImageURL.poster(posterPath, width: 400)
    }
}
