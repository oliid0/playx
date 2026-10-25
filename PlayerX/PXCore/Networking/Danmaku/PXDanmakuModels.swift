import Foundation

enum PXDanmakuMode: String, Codable, Hashable, Sendable {
    case scroll
    case top
    case bottom
}

struct PXDanmakuComment: Identifiable, Hashable, Sendable {
    var id: String
    var text: String
    var time: Double
    var mode: PXDanmakuMode
    var color: UInt32
    var fontSize: Double

    init(
        id: String = UUID().uuidString,
        text: String,
        time: Double,
        mode: PXDanmakuMode = .scroll,
        color: UInt32 = 0xFFFFFF,
        fontSize: Double = 16
    ) {
        self.id = id
        self.text = text
        self.time = time
        self.mode = mode
        self.color = color
        self.fontSize = fontSize
    }

    init?(raw: PXDanmakuRawComment, index: Int) {
        let fields = raw.p.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count >= 4,
              let seconds = Double(fields[0]),
              let modeValue = Int(fields[1]),
              let colorValue = UInt32(fields[2]) else { return nil }
        let text = raw.m.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        time = seconds
        mode = modeValue == 4 ? .bottom : (modeValue == 5 ? .top : .scroll)
        color = colorValue
        fontSize = fields.count > 3 ? (Double(fields[3]) ?? 16) : 16
        self.text = text
        self.id = raw.cid.map(String.init) ?? "\(index)-\(raw.p)-\(text)"
    }
}

struct PXDanmakuRawComment: Decodable, Hashable, Sendable {
    var cid: Int64?
    var p: String
    var m: String
}

struct PXDanmakuEpisode: Identifiable, Hashable, Sendable {
    var episodeID: Int64
    var animeID: Int?
    var animeTitle: String?
    var episodeTitle: String?

    var id: Int64 { episodeID }
}

struct PXDanmakuSearchResponse: Decodable, Sendable {
    struct Anime: Decodable, Sendable {
        var animeID: Int?
        var animeTitle: String?
        var type: String?
        var typeDescription: String?
        var episodes: [Episode]?
    }
    struct Episode: Decodable, Sendable {
        var episodeID: Int64
        var episodeTitle: String?
    }

    var success: Bool?
    var errorCode: Int?
    var errorMessage: String?
    var animes: [Anime]?
}

struct PXDanmakuCommentsResponse: Decodable, Sendable {
    var count: Int?
    var comments: [PXDanmakuRawComment]?
}
