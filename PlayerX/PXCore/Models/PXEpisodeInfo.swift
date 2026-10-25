import Foundation

struct PXEpisodeInfo: Codable, Identifiable, Hashable, Sendable {
    var seasonNumber: Int
    var episodeNumber: Int
    var name: String?
    var overview: String?
    var stillPath: String?
    var airDate: String?
    var runtimeMinutes: Int?
    var rating: Double?

    var id: String { "s\(seasonNumber)e\(episodeNumber)" }

    init(
        seasonNumber: Int = 1,
        episodeNumber: Int,
        name: String? = nil,
        overview: String? = nil,
        stillPath: String? = nil,
        airDate: String? = nil,
        runtimeMinutes: Int? = nil,
        rating: Double? = nil
    ) {
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.name = name
        self.overview = overview
        self.stillPath = stillPath
        self.airDate = airDate
        self.runtimeMinutes = runtimeMinutes
        self.rating = rating
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return "第 \(episodeNumber) 集"
    }

    var stillURL: URL? {
        PXImageURL.still(stillPath, width: 640)
    }

    var episodeLabel: String {
        seasonNumber > 0 ? "S\(seasonNumber) · E\(episodeNumber)" : "E\(episodeNumber)"
    }
}
