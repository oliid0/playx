import Foundation

struct PXMediaServerPublicInfo: Decodable {
    var serverName: String?
    var version: String?
    var id: String?
}

struct PXMediaServerUser: Decodable, Identifiable {
    var id: String
    var name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

struct PXMediaServerAuthResponse: Decodable {
    var user: PXMediaServerUser?
    var accessToken: String?
    var serverId: String?

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case accessToken = "AccessToken"
        case serverId = "ServerId"
    }
}

struct PXMediaServerView: Decodable, Identifiable {
    var id: String
    var name: String
    var collectionType: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case collectionType = "CollectionType"
    }

    var displayName: String {
        switch (collectionType ?? "").lowercased() {
        case "movies": "电影"
        case "tvshows": "剧集"
        case "boxsets": "合集"
        case "homevideos": "家庭视频"
        case "music": "音乐"
        case "books": "书籍"
        default: name
        }
    }

    var bestKind: PXMediaKind {
        let haystack = "\(name) \(collectionType ?? "")".lowercased()
        if haystack.contains("anime") || haystack.contains("动漫") || haystack.contains("动画") {
            return .anime
        }
        switch (collectionType ?? "").lowercased() {
        case "movies": return .movie
        case "tvshows": return .series
        case "homevideos": return .documentary
        default: return .series
        }
    }
}

struct PXMediaServerItemsResponse: Decodable {
    var items: [PXMediaServerItem]?
    var totalRecordCount: Int?
    var startIndex: Int?

    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
        case startIndex = "StartIndex"
    }
}

struct PXMediaServerUserData: Decodable {
    var playedPercentage: Double?
    var playbackPositionTicks: Int64?
    var played: Bool?
    var unplayedItemCount: Int?

    enum CodingKeys: String, CodingKey {
        case playedPercentage = "PlayedPercentage"
        case playbackPositionTicks = "PlaybackPositionTicks"
        case played = "Played"
        case unplayedItemCount = "UnplayedItemCount"
    }
}

struct PXMediaServerMediaStream: Decodable {
    var type: String?
    var codec: String?
    var language: String?
    var displayTitle: String?
    var channels: Int?

    enum CodingKeys: String, CodingKey {
        case type = "Type"
        case codec = "Codec"
        case language = "Language"
        case displayTitle = "DisplayTitle"
        case channels = "Channels"
    }
}

struct PXMediaServerMediaSource: Decodable, Identifiable {
    var id: String?
    var name: String?
    var container: String?
    var size: Int64?
    var supportsDirectPlay: Bool?
    var supportsDirectStream: Bool?
    var mediaStreams: [PXMediaServerMediaStream]?

    var identifier: String { id ?? name ?? "source" }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case container = "Container"
        case size = "Size"
        case supportsDirectPlay = "SupportsDirectPlay"
        case supportsDirectStream = "SupportsDirectStream"
        case mediaStreams = "MediaStreams"
    }
}

struct PXMediaServerItem: Decodable, Identifiable {
    var id: String
    var name: String
    var type: String?
    var collectionType: String?
    var overview: String?
    var productionYear: Int?
    var runTimeTicks: Int64?
    var genres: [String]?
    var imageTags: [String: String]?
    var backdropImageTags: [String]?
    var childCount: Int?
    var recursiveItemCount: Int?
    var indexNumber: Int?
    var parentIndexNumber: Int?
    var seriesId: String?
    var seasonId: String?
    var seriesName: String?
    var officialRating: String?
    var communityRating: Double?
    var mediaSources: [PXMediaServerMediaSource]?
    var userData: PXMediaServerUserData?
    var providerIds: [String: String]?
    var dateCreated: String?
    var premiereDate: String?

    var primaryTag: String? { imageTags?["Primary"] }
    var backdropTag: String? { backdropImageTags?.first ?? imageTags?["Backdrop"] }

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case type = "Type"
        case collectionType = "CollectionType"
        case overview = "Overview"
        case productionYear = "ProductionYear"
        case runTimeTicks = "RunTimeTicks"
        case genres = "Genres"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case childCount = "ChildCount"
        case recursiveItemCount = "RecursiveItemCount"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case seriesId = "SeriesId"
        case seasonId = "SeasonId"
        case seriesName = "SeriesName"
        case officialRating = "OfficialRating"
        case communityRating = "CommunityRating"
        case mediaSources = "MediaSources"
        case userData = "UserData"
        case providerIds = "ProviderIds"
        case dateCreated = "DateCreated"
        case premiereDate = "PremiereDate"
    }
}

enum PXMediaServerMapping {
    static func kind(for item: PXMediaServerItem, libraryKind: PXMediaKind? = nil) -> PXMediaKind {
        if let libraryKind, libraryKind != .series { return libraryKind }
        let type = (item.type ?? "").lowercased()
        let haystack = ([item.name, item.seriesName ?? ""] + (item.genres ?? [])).joined(separator: " ").lowercased()
        if haystack.contains("anime") || haystack.contains("动漫") || haystack.contains("动画") {
            return .anime
        }
        if type == "movie" { return .movie }
        if type == "boxset" { return .series }
        return .series
    }

    static func drama(from item: PXMediaServerItem, configuration: PXSourceConfiguration, libraryKind: PXMediaKind? = nil) -> Drama {
        let kind = kind(for: item, libraryKind: libraryKind)
        let episodes = item.recursiveItemCount ?? item.childCount
        var tags = item.genres ?? []
        if let rating = item.officialRating { tags.append(rating) }
        if let year = item.productionYear { tags.append(String(year)) }
        return Drama(
            id: "\(configuration.id):\(item.id)",
            source: configuration.id,
            sourceId: item.id,
            title: item.name,
            description: item.overview,
            cover: imageURL(itemID: item.id, tag: item.primaryTag, configuration: configuration)?.absoluteString,
            episodes: episodes,
            category: kind.title,
            vip: false,
            heat: item.communityRating.map { String(format: "%.1f", $0) },
            onlineDate: item.productionYear.map(String.init),
            tags: tags,
            releaseStatus: item.userData?.played == true ? "已看" : nil
        )
    }

    static func imageURL(itemID: String, tag: String?, configuration: PXSourceConfiguration, maxWidth: Int = 800) -> URL? {
        guard var components = URLComponents(url: configuration.normalizedBaseURL?.appendingPathComponent("Items/\(itemID)/Images/Primary") ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        var query = [
            URLQueryItem(name: "maxWidth", value: String(maxWidth)),
            URLQueryItem(name: "quality", value: "85"),
        ]
        if let tag { query.append(URLQueryItem(name: "tag", value: tag)) }
        if !configuration.token.isEmpty {
            query.append(URLQueryItem(name: "api_key", value: configuration.token))
        }
        components.queryItems = query
        return components.url
    }

    static func backdropURL(itemID: String, tag: String?, configuration: PXSourceConfiguration) -> URL? {
        guard var components = URLComponents(url: configuration.normalizedBaseURL?.appendingPathComponent("Items/\(itemID)/Images/Backdrop") ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false) else {
            return nil
        }
        var query = [URLQueryItem(name: "maxWidth", value: "1600"), URLQueryItem(name: "quality", value: "85")]
        if let tag { query.append(URLQueryItem(name: "tag", value: tag)) }
        if !configuration.token.isEmpty { query.append(URLQueryItem(name: "api_key", value: configuration.token)) }
        components.queryItems = query
        return components.url
    }
}
