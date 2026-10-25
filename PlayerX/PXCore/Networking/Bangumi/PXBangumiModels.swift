import Foundation

enum PXBangumiSubjectType: Int, Codable, CaseIterable, Identifiable {
    case book = 1
    case anime = 2
    case music = 3
    case game = 4
    case real = 6

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .book: "书籍"
        case .anime: "动画"
        case .music: "音乐"
        case .game: "游戏"
        case .real: "三次元"
        }
    }
}

enum PXBangumiCollectionType: Int, Codable, CaseIterable, Identifiable {
    case wish = 1
    case doing = 2
    case done = 3
    case onHold = 4
    case dropped = 5

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .wish: "想看"
        case .doing: "在看"
        case .done: "看过"
        case .onHold: "搁置"
        case .dropped: "抛弃"
        }
    }
    var symbol: String {
        switch self {
        case .wish: "heart"
        case .doing: "play.circle"
        case .done: "checkmark.circle"
        case .onHold: "pause.circle"
        case .dropped: "xmark.circle"
        }
    }
}

struct PXBangumiImages: Codable, Hashable, Sendable {
    var large: String?
    var common: String?
    var medium: String?
    var small: String?
    var grid: String?

    var best: URL? {
        URL(string: large ?? common ?? medium ?? small ?? grid ?? "")
    }
}

struct PXBangumiRating: Codable, Hashable, Sendable {
    var score: Double?
    var total: Int?
    var count: [Int: Int]?

    enum CodingKeys: String, CodingKey { case score, total, count }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try? container.decodeIfPresent(Double.self, forKey: .score)
        total = try? container.decodeIfPresent(Int.self, forKey: .total)
        count = try? container.decodeIfPresent([Int: Int].self, forKey: .count)
    }

    init(score: Double? = nil, total: Int? = nil, count: [Int: Int]? = nil) {
        self.score = score
        self.total = total
        self.count = count
    }
}

struct PXBangumiTag: Codable, Hashable, Sendable {
    var name: String
    var count: Int?
}

struct PXBangumiInfoboxValue: Codable, Hashable, Sendable {
    var v: String?
    var k: String?
}

struct PXBangumiInfobox: Codable, Hashable, Sendable, Identifiable {
    var key: String
    var value: [PXBangumiInfoboxValue]?
    var id: String { key }

    var display: String {
        (value ?? []).compactMap(\.v).filter { !$0.isEmpty }.joined(separator: "、")
    }
}

struct PXBangumiSubject: Codable, Identifiable, Hashable, Sendable {
    var id: Int
    var name: String
    var nameCN: String?
    var summary: String?
    var images: PXBangumiImages?
    var type: Int?
    var eps: Int?
    var volumes: Int?
    var airDate: String?
    var airWeekday: Int?
    var rating: PXBangumiRating?
    var tags: [PXBangumiTag]?
    var infobox: [PXBangumiInfobox]?
    var platform: String?
    var nsfw: Bool?
    var collection: PXBangumiCollectionType?

    enum CodingKeys: String, CodingKey {
        case id, name, summary, images, type, eps, volumes, rating, tags, infobox, platform, nsfw, collection
        case nameCN = "name_cn"
        case airDate = "date"
        case airWeekday = "air_weekday"
    }

    var displayTitle: String {
        if let nameCN, !nameCN.isEmpty { return nameCN }
        return name
    }

    var subtitle: String? {
        guard let nameCN, !nameCN.isEmpty, nameCN != name else { return name }
        return name
    }

    var imageURL: URL? { images?.best }
    var scoreText: String? {
        guard let score = rating?.score, score > 0 else { return nil }
        return String(format: "%.1f", score)
    }
    var episodesText: String? {
        guard let eps, eps > 0 else { return nil }
        return "全 \(eps) 话"
    }
    var year: Int? {
        guard let airDate, airDate.count >= 4 else { return nil }
        return Int(airDate.prefix(4))
    }
    var displayTags: [String] {
        Array((tags ?? []).sorted { ($0.count ?? 0) > ($1.count ?? 0) }.prefix(8).map(\.name))
    }
}

struct PXBangumiEpisode: Codable, Identifiable, Hashable, Sendable {
    var id: Int
    var type: Int?
    var name: String?
    var nameCN: String?
    var sort: Double?
    var ep: Double?
    var airDate: String?
    var duration: String?
    var desc: String?
    var airdate: String?

    enum CodingKeys: String, CodingKey {
        case id, type, name, sort, ep, duration, desc, airdate
        case nameCN = "name_cn"
        case airDate = "airdate"
    }

    var displayName: String {
        if let nameCN, !nameCN.isEmpty { return nameCN }
        if let name, !name.isEmpty { return name }
        return "第 \(Int(ep ?? sort ?? 0)) 话"
    }

    var number: Int { Int(ep ?? sort ?? 0) }
}

struct PXBangumiCalendarDay: Codable, Identifiable, Hashable, Sendable {
    var weekday: PXBangumiWeekday
    var items: [PXBangumiSubject]

    var id: Int { weekday.id }
}

struct PXBangumiWeekday: Codable, Hashable, Sendable {
    var id: Int
    var cn: String
    var en: String?
}

struct PXBangumiUser: Codable, Identifiable, Hashable, Sendable {
    var id: Int
    var username: String
    var nickname: String
    var avatar: PXBangumiImages?
    var sign: String?

    var displayName: String {
        nickname.isEmpty ? username : nickname
    }
}

struct PXBangumiCollection: Codable, Identifiable, Hashable, Sendable {
    var subjectID: Int
    var type: PXBangumiCollectionType?
    var rate: Int?
    var epStatus: Int?
    var volStatus: Int?
    var updatedAt: String?
    var subject: PXBangumiSubject?

    var id: Int { subjectID }

    enum CodingKeys: String, CodingKey {
        case type, rate, subject
        case subjectID = "subject_id"
        case epStatus = "ep_status"
        case volStatus = "vol_status"
        case updatedAt = "updated_at"
    }
}

struct PXBangumiSearchResponse: Decodable, Sendable {
    var data: [PXBangumiSubject]?
    var total: Int?
}

struct PXBangumiPaged<T: Decodable & Sendable>: Decodable, Sendable {
    var data: [T]
    var total: Int?
}
