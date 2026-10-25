import Foundation

struct PXMacCMSCategory: Decodable, Identifiable, Hashable {
    var id: String
    var name: String

    enum CodingKeys: String, CodingKey {
        case id = "type_id"
        case name = "type_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(container, .id) ?? ""
        name = Self.string(container, .name) ?? "未命名"
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    static func string(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Double.self, forKey: key) { return String(Int(value)) }
        return nil
    }
}

struct PXMacCMSItem: Decodable, Identifiable, Hashable {
    var vodID: String
    var name: String
    var poster: String?
    var content: String?
    var year: String?
    var area: String?
    var language: String?
    var remarks: String?
    var typeName: String?
    var playFrom: String?
    var playURL: String?

    var id: String { vodID }

    enum CodingKeys: String, CodingKey {
        case vodID = "vod_id"
        case name = "vod_name"
        case poster = "vod_pic"
        case content = "vod_content"
        case year = "vod_year"
        case area = "vod_area"
        case language = "vod_lang"
        case remarks = "vod_remarks"
        case typeName = "type_name"
        case playFrom = "vod_play_from"
        case playURL = "vod_play_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vodID = Self.string(container, .vodID) ?? UUID().uuidString
        name = Self.string(container, .name) ?? "未命名"
        poster = Self.string(container, .poster)
        content = Self.string(container, .content)
        year = Self.string(container, .year)
        area = Self.string(container, .area)
        language = Self.string(container, .language)
        remarks = Self.string(container, .remarks)
        typeName = Self.string(container, .typeName)
        playFrom = Self.string(container, .playFrom)
        playURL = Self.string(container, .playURL)
    }

    init(
        vodID: String,
        name: String,
        poster: String? = nil,
        content: String? = nil,
        year: String? = nil,
        area: String? = nil,
        language: String? = nil,
        remarks: String? = nil,
        typeName: String? = nil,
        playFrom: String? = nil,
        playURL: String? = nil
    ) {
        self.vodID = vodID
        self.name = name
        self.poster = poster
        self.content = content
        self.year = year
        self.area = area
        self.language = language
        self.remarks = remarks
        self.typeName = typeName
        self.playFrom = playFrom
        self.playURL = playURL
    }

    static func string(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let value = try? container.decode(String.self, forKey: key) {
            return value.isEmpty ? nil : value
        }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Double.self, forKey: key) { return String(Int(value)) }
        return nil
    }

    var playEntries: [(String, String)] {
        guard let playURL else { return [] }
        let groups = playURL.components(separatedBy: "$$$")
        for group in groups {
            let entries = group.components(separatedBy: "#").enumerated().compactMap { index, raw -> (String, String)? in
                let parts = raw.components(separatedBy: "$")
                guard parts.count >= 2 else { return nil }
                let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let url = parts.dropFirst().joined(separator: "$").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !url.isEmpty else { return nil }
                return (name.isEmpty ? "第 \(index + 1) 集" : name, url)
            }
            if !entries.isEmpty { return entries }
        }
        return []
    }
}

struct PXMacCMSResponse: Decodable {
    var code: Int?
    var msg: String?
    var page: Int?
    var pageCount: Int?
    var total: Int?
    var list: [PXMacCMSItem]?
    var categories: [PXMacCMSCategory]?

    enum CodingKeys: String, CodingKey {
        case code, msg, page, total, list
        case pageCount = "pagecount"
        case categories = "class"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try? container.decode(Int.self, forKey: .code)
        msg = try? container.decode(String.self, forKey: .msg)
        page = (try? container.decode(Int.self, forKey: .page)) ?? Int((try? container.decode(String.self, forKey: .page)) ?? "")
        pageCount = (try? container.decode(Int.self, forKey: .pageCount)) ?? Int((try? container.decode(String.self, forKey: .pageCount)) ?? "")
        total = (try? container.decode(Int.self, forKey: .total)) ?? Int((try? container.decode(String.self, forKey: .total)) ?? "")
        list = try? container.decode([PXMacCMSItem].self, forKey: .list)
        categories = try? container.decode([PXMacCMSCategory].self, forKey: .categories)
    }
}
