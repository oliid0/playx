import Foundation

enum PXMoviePilotError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case status(Int, String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "MoviePilot 未配置"
        case .unauthorized: return "MoviePilot 登录已失效"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "MoviePilot HTTP \(code)：\(message)" }
            return "MoviePilot HTTP \(code)"
        case .decoding: return "MoviePilot 响应无法解析"
        case .transport(let message): return message
        }
    }
}

/// MoviePilot v3 客户端。覆盖找片、资源搜索、订阅、下载四个主流程；SSE 资源
/// 搜索用 `URLSession.bytes` 逐行聚合，首条结果到达即可展示，不必等全站跑完。
actor PXMoviePilotClient {
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 300
            configuration.httpAdditionalHeaders = [
                "User-Agent": "PlayerX/1.0 (MoviePilot)",
                "Accept": "application/json",
            ]
            self.session = URLSession(configuration: configuration)
        }
    }

    func login(baseURL: URL, username: String, password: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/login/access-token"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password),
        ]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        let data = try await send(request, token: nil)
        struct TokenResponse: Decodable {
            var accessToken: String
            enum CodingKeys: String, CodingKey { case accessToken = "access_token" }
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data).accessToken
    }

    func currentUser(baseURL: URL, token: String) async throws -> PXMoviePilotUser {
        let data = try await getData(baseURL: baseURL, path: "api/v1/user/current", token: token)
        return try decode(PXMoviePilotUser.self, from: data)
    }

    func searchMedia(baseURL: URL, token: String, title: String) async throws -> [PXMoviePilotMedia] {
        let data = try await getData(
            baseURL: baseURL,
            path: "api/v1/media/search",
            query: [
                .init(name: "title", value: title),
                .init(name: "type", value: "media"),
                .init(name: "page", value: "1"),
                .init(name: "count", value: "24"),
            ],
            token: token
        )
        return try unwrapObjects(data).map(PXMoviePilotMedia.init(raw:))
    }

    /// SSE 搜索：`/api/v1/search/title` 会逐站点推送，每个 `data:` 行是一条 JSON。
    func searchTorrents(
        baseURL: URL,
        token: String,
        title: String,
        media: PXMoviePilotMedia?
    ) async throws -> [PXMoviePilotTorrent] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/v1/search/title"),
            resolvingAgainstBaseURL: false
        )
        var query: [URLQueryItem] = [
            .init(name: "title", value: title),
            .init(name: "page", value: "1"),
        ]
        if let media {
            if let type = media.type { query.append(.init(name: "media_type", value: type)) }
            if let year = media.year { query.append(.init(name: "year", value: year)) }
            if let season = media.season { query.append(.init(name: "season", value: String(season))) }
        }
        components?.queryItems = query
        guard let url = components?.url else { throw PXMoviePilotError.transport("URL 拼接失败") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PXMoviePilotError.status((response as? HTTPURLResponse)?.statusCode ?? -1, nil)
        }
        var torrents: [PXMoviePilotTorrent] = []
        var buffer = ""
        for try await line in bytes.lines {
            guard !Task.isCancelled else { break }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data:") else {
                if trimmed.hasPrefix("{") { buffer += trimmed }
                continue
            }
            let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
            guard !payload.isEmpty, payload != "[DONE]" else { continue }
            if let data = payload.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
                torrents.append(contentsOf: Self.torrents(from: parsed))
            }
        }
        if torrents.isEmpty, !buffer.isEmpty, let data = buffer.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            torrents.append(contentsOf: Self.torrents(from: parsed))
        }
        return torrents
    }

    func subscriptions(baseURL: URL, token: String) async throws -> [PXMoviePilotSubscription] {
        let data = try await getData(baseURL: baseURL, path: "api/v1/subscribe/", token: token)
        return try unwrapObjects(data).map(PXMoviePilotSubscription.init(raw:))
    }

    func addSubscription(baseURL: URL, token: String, media: PXMoviePilotMedia, season: Int?) async throws {
        var body = media.raw
        body["name"] = .string(media.title)
        if let type = media.type { body["type"] = .string(type) }
        if let year = media.year { body["year"] = .string(year) }
        if let tmdbID = media.tmdbID { body["tmdbid"] = .number(Double(tmdbID)) }
        if let bangumiID = media.bangumiID { body["bangumiid"] = .number(Double(bangumiID)) }
        if let poster = media.posterURL?.absoluteString { body["poster"] = .string(poster) }
        if let overview = media.overview { body["overview"] = .string(overview) }
        if let season = season ?? media.season { body["season"] = .number(Double(season)) }
        _ = try await postJSON(
            baseURL: baseURL,
            path: "api/v1/subscribe/",
            token: token,
            body: .object(body),
            method: "POST"
        )
    }

    func deleteSubscription(baseURL: URL, token: String, id: Int) async throws {
        _ = try await send(
            makeRequest(baseURL: baseURL, path: "api/v1/subscribe/\(id)", method: "DELETE", token: token),
            token: token
        )
    }

    func downloads(baseURL: URL, token: String) async throws -> [PXMoviePilotDownload] {
        let data = try await getData(baseURL: baseURL, path: "api/v1/download/", token: token)
        return try unwrapObjects(data).map(PXMoviePilotDownload.init(raw:))
    }

    func addDownload(baseURL: URL, token: String, media: PXMoviePilotMedia?, torrent: PXMoviePilotTorrent) async throws {
        var body: [String: PXJSONValue] = ["torrent_in": .object(torrent.raw)]
        if let media { body["media_in"] = .object(media.raw) }
        _ = try await postJSON(
            baseURL: baseURL,
            path: "api/v1/download/",
            token: token,
            body: .object(body),
            method: "POST"
        )
    }

    func deleteDownload(baseURL: URL, token: String, hash: String) async throws {
        let encoded = hash.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? hash
        _ = try await send(
            makeRequest(baseURL: baseURL, path: "api/v1/download/\(encoded)", method: "DELETE", token: token),
            token: token
        )
    }

    private func getData(
        baseURL: URL,
        path: String,
        query: [URLQueryItem] = [],
        token: String
    ) async throws -> Data {
        var request = makeRequest(baseURL: baseURL, path: path, method: "GET", token: token)
        if !query.isEmpty {
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            components?.queryItems = query
            request.url = components?.url
        }
        return try await send(request, token: token)
    }

    private func postJSON(
        baseURL: URL,
        path: String,
        token: String,
        body: PXJSONValue,
        method: String
    ) async throws -> Data {
        var request = makeRequest(baseURL: baseURL, path: path, method: method, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request, token: token)
    }

    private func makeRequest(baseURL: URL, path: String, method: String, token: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(_ request: URLRequest, token: String?) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw PXMoviePilotError.transport("没有 HTTP 响应")
            }
            switch http.statusCode {
            case 200..<300: return data
            case 401, 403: throw PXMoviePilotError.unauthorized
            default:
                throw PXMoviePilotError.status(
                    http.statusCode,
                    String(data: data.prefix(300), encoding: .utf8)
                )
            }
        } catch let error as PXMoviePilotError {
            throw error
        } catch {
            throw PXMoviePilotError.transport(error.localizedDescription)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw PXMoviePilotError.decoding(error.localizedDescription) }
    }

    private func unwrapObjects(_ data: Data) throws -> [[String: PXJSONValue]] {
        guard let parsed = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            throw PXMoviePilotError.decoding("不是合法 JSON")
        }
        let payload: Any
        if let object = parsed as? [String: Any],
           object.keys.contains("success"), let inner = object["data"] {
            payload = inner
        } else {
            payload = parsed
        }
        guard let array = payload as? [Any] else {
            throw PXMoviePilotError.decoding("响应不是数组")
        }
        return try array.map { element in
            guard let object = element as? [String: Any] else {
                throw PXMoviePilotError.decoding("数组元素不是对象")
            }
            return object.mapValues(PXJSONValue.convert)
        }
    }

    nonisolated private static func torrents(from parsed: Any) -> [PXMoviePilotTorrent] {
        if let array = parsed as? [Any] {
            return array.flatMap(torrents(from:))
        }
        guard let object = parsed as? [String: Any] else { return [] }
        if let data = object["data"] {
            return torrents(from: data)
        }
        if object["title"] != nil || object["enclosure"] != nil || object["magnet"] != nil {
            return [PXMoviePilotTorrent(raw: object.mapValues(PXJSONValue.convert))]
        }
        return []
    }
}
