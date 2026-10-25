import Foundation

/// Bangumi v0 / p1 API。公开接口不需要令牌；收藏与进度需要用户 OAuth token。
actor PXBangumiClient {
    static let apiBase = URL(string: "https://api.bgm.tv")!
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 30
            configuration.httpAdditionalHeaders = [
                "User-Agent": "PlayerX/1.0 (https://github.com/oliid0/playx)",
                "Accept": "application/json",
            ]
            self.session = URLSession(configuration: configuration)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func calendar() async throws -> [PXBangumiCalendarDay] {
        try await get([PXBangumiCalendarDay].self, path: "/calendar", token: nil)
    }

    func search(_ keyword: String, type: PXBangumiSubjectType = .anime, limit: Int = 24) async throws -> [PXBangumiSubject] {
        let body: [String: Any] = [
            "keyword": keyword,
            "sort": "match",
            "filter": ["type": [type.rawValue]],
        ]
        let data = try await request(
            path: "/v0/search/subjects",
            method: "POST",
            query: [URLQueryItem(name: "limit", value: String(limit))],
            json: body,
            token: nil
        )
        let response = try decode(PXBangumiSearchResponse.self, from: data)
        return response.data ?? []
    }

    func subject(id: Int) async throws -> PXBangumiSubject {
        try await get(PXBangumiSubject.self, path: "/v0/subjects/\(id)", token: nil)
    }

    func episodes(subjectID: Int, type: Int = 0, limit: Int = 100) async throws -> [PXBangumiEpisode] {
        let response = try await get(
            PXBangumiPaged<PXBangumiEpisode>.self,
            path: "/v0/episodes",
            query: [
                URLQueryItem(name: "subject_id", value: String(subjectID)),
                URLQueryItem(name: "type", value: String(type)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: "0"),
            ],
            token: nil
        )
        return response.data
    }

    func me(token: String) async throws -> PXBangumiUser {
        try await get(PXBangumiUser.self, path: "/v0/me", token: token)
    }

    func collections(username: String, type: PXBangumiCollectionType? = nil, limit: Int = 100) async throws -> [PXBangumiCollection] {
        var query = [
            URLQueryItem(name: "subject_type", value: "2"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: "0"),
        ]
        if let type { query.append(.init(name: "type", value: String(type.rawValue))) }
        let response = try await get(
            PXBangumiPaged<PXBangumiCollection>.self,
            path: "/v0/users/\(username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username)/collections",
            query: query,
            token: nil
        )
        return response.data
    }

    func updateCollection(subjectID: Int, type: PXBangumiCollectionType?, rate: Int?, token: String) async throws {
        guard !token.isEmpty else { throw PXBangumiError.notConfigured }
        var body: [String: Any] = [:]
        if let type { body["type"] = type.rawValue }
        if let rate { body["rate"] = rate }
        let data = try await request(
            path: "/v0/users/-/collections/\(subjectID)",
            method: "POST",
            json: body,
            token: token
        )
        _ = data
    }

    func updateEpisode(episodeID: Int, type: Int, token: String) async throws {
        guard !token.isEmpty else { throw PXBangumiError.notConfigured }
        _ = try await request(
            path: "/v0/users/-/collections/-/episodes/\(episodeID)",
            method: "PUT",
            json: ["type": type],
            token: token
        )
    }

    private func get<T: Decodable>(
        _ type: T.Type,
        path: String,
        query: [URLQueryItem] = [],
        token: String?
    ) async throws -> T {
        let data = try await request(path: path, method: "GET", query: query, token: token)
        return try decode(T.self, from: data)
    }

    private func request(
        path: String,
        method: String,
        query: [URLQueryItem] = [],
        json: [String: Any]? = nil,
        token: String?
    ) async throws -> Data {
        var components = URLComponents(url: Self.apiBase.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = query.isEmpty ? nil : query
        guard let url = components?.url else { throw PXBangumiError.transport("URL 拼接失败") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("PlayerX/1.0 (https://github.com/oliid0/playx)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PXBangumiError.transport("没有 HTTP 响应") }
        switch http.statusCode {
        case 200..<300: return data
        case 401, 403: throw PXBangumiError.unauthorized
        case 404: throw PXBangumiError.notFound
        default:
            throw PXBangumiError.status(http.statusCode, String(data: data.prefix(300), encoding: .utf8))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) }
        catch { throw PXBangumiError.decoding(error.localizedDescription) }
    }
}
