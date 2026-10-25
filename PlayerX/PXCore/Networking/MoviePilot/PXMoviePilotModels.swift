import Foundation

struct PXMoviePilotUser: Decodable, Identifiable, Hashable, Sendable {
    var id: Int?
    var name: String
    var email: String?
    var avatar: String?
    var isSuperuser: Bool?

    var identifier: String { String(id ?? 0) }
}

struct PXMoviePilotMedia: Identifiable, Hashable, Sendable {
    var raw: [String: PXJSONValue]
    var title: String
    var type: String?
    var year: String?
    var tmdbID: Int?
    var doubanID: String?
    var bangumiID: Int?
    var season: Int?
    var posterURL: URL?
    var overview: String?

    var id: String {
        if let tmdbID { return "tmdb:\(tmdbID)" }
        if let bangumiID { return "bangumi:\(bangumiID)" }
        return "\(title)-\(year ?? "")"
    }

    init(raw: [String: PXJSONValue]) {
        self.raw = raw
        title = raw["title"]?.stringValue ?? raw["name"]?.stringValue ?? "未命名"
        type = raw["type"]?.stringValue ?? raw["media_type"]?.stringValue
        year = raw["year"]?.stringValue ?? raw["release_year"]?.stringValue
        tmdbID = raw["tmdb_id"]?.intValue ?? raw["tmdbid"]?.intValue
        doubanID = raw["douban_id"]?.stringValue ?? raw["doubanid"]?.stringValue
        bangumiID = raw["bangumi_id"]?.intValue ?? raw["bangumiid"]?.intValue
        season = raw["season"]?.intValue
        let poster = raw["poster_path"]?.stringValue ?? raw["poster"]?.stringValue
        posterURL = poster.flatMap { value in
            if value.hasPrefix("http") { return URL(string: value) }
            if value.hasPrefix("/") { return URL(string: "https://image.tmdb.org/t/p/w500\(value)") }
            return nil
        }
        overview = raw["overview"]?.stringValue ?? raw["description"]?.stringValue
    }
}

struct PXMoviePilotTorrent: Identifiable, Hashable, Sendable {
    var raw: [String: PXJSONValue]
    var title: String
    var description: String?
    var siteName: String?
    var size: Int64?
    var seeders: Int?
    var peers: Int?
    var hash: String?
    var magnet: String?
    var enclosure: String?
    var pubDate: String?

    var id: String { hash ?? "\(title)-\(siteName ?? "")" }

    init(raw: [String: PXJSONValue]) {
        self.raw = raw
        title = raw["title"]?.stringValue ?? raw["name"]?.stringValue ?? "未命名资源"
        description = raw["description"]?.stringValue
        siteName = raw["site_name"]?.stringValue ?? raw["site"]?.stringValue
        size = raw["size"]?.intValue.map(Int64.init) ?? raw["size"]?.doubleValue.map(Int64.init)
        seeders = raw["seeders"]?.intValue
        peers = raw["peers"]?.intValue
        hash = raw["hash"]?.stringValue
        magnet = raw["magnet"]?.stringValue
        enclosure = raw["enclosure"]?.stringValue
        pubDate = raw["pubdate"]?.stringValue ?? raw["pub_date"]?.stringValue
    }

    var sizeText: String? {
        guard let size, size > 0 else { return nil }
        return PXFormat.byteCount(size)
    }
}

struct PXMoviePilotSubscription: Identifiable, Hashable, Sendable {
    var raw: [String: PXJSONValue]
    var id: Int
    var name: String
    var year: String?
    var season: Int?
    var tmdbID: Int?
    var posterURL: URL?
    var state: String?
    var totalEpisodes: Int?
    var currentEpisodes: Int?

    init(raw: [String: PXJSONValue]) {
        self.raw = raw
        id = raw["id"]?.intValue ?? 0
        name = raw["name"]?.stringValue ?? "未命名订阅"
        year = raw["year"]?.stringValue
        season = raw["season"]?.intValue
        tmdbID = raw["tmdbid"]?.intValue ?? raw["tmdb_id"]?.intValue
        let poster = raw["poster"]?.stringValue
        posterURL = poster.flatMap { value in
            if value.hasPrefix("http") { return URL(string: value) }
            if value.hasPrefix("/") { return URL(string: "https://image.tmdb.org/t/p/w500\(value)") }
            return nil
        }
        state = raw["state"]?.stringValue
        totalEpisodes = raw["total_episode"]?.intValue ?? raw["total_episodes"]?.intValue
        currentEpisodes = raw["current_episode"]?.intValue ?? raw["current_episodes"]?.intValue
    }
}

struct PXMoviePilotDownload: Identifiable, Hashable, Sendable {
    var raw: [String: PXJSONValue]
    var id: String
    var name: String
    var progress: Double
    var size: Int64?
    var speed: Double?
    var state: String?
    var posterURL: URL?

    init(raw: [String: PXJSONValue]) {
        self.raw = raw
        id = raw["hash"]?.stringValue ?? raw["id"]?.stringValue ?? UUID().uuidString
        name = raw["name"]?.stringValue ?? raw["title"]?.stringValue ?? "下载任务"
        progress = raw["progress"]?.doubleValue ?? 0
        if progress > 1 { progress /= 100 }
        size = raw["size"]?.intValue.map(Int64.init) ?? raw["total_size"]?.intValue.map(Int64.init)
        speed = raw["speed"]?.doubleValue
        state = raw["state"]?.stringValue ?? raw["status"]?.stringValue
        let poster = raw["poster"]?.stringValue
        posterURL = poster.flatMap { URL(string: $0) }
    }

    var speedText: String? {
        guard let speed, speed > 0 else { return nil }
        return "\(PXFormat.byteCount(Int64(speed)))/s"
    }
}
