import Foundation

enum PXMediaServerError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case status(Int, String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "媒体服务器未配置"
        case .unauthorized: return "媒体服务器登录失效"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "媒体服务器 HTTP \(code)：\(message)" }
            return "媒体服务器 HTTP \(code)"
        case .decoding: return "媒体服务器响应无法解析"
        case .transport(let message): return message
        }
    }
}

final class PXMediaServerClient {
    let configuration: PXSourceConfiguration
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(configuration: PXSourceConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = 20
            sessionConfiguration.timeoutIntervalForResource = 40
            sessionConfiguration.httpAdditionalHeaders = ["Accept": "application/json"]
            self.session = URLSession(configuration: sessionConfiguration)
        }
    }

    var baseURL: URL? { configuration.normalizedBaseURL }
    var token: String { configuration.token }
    var userID: String { configuration.userID }
    var authorization: String {
        var parts = [
            "MediaBrowser Client=\"PlayerX\"",
            "Device=\"Apple\"",
            "DeviceId=\"\(configuration.id)\"",
            "Version=\"1.0\"",
        ]
        if !token.isEmpty { parts.append("Token=\"\(token)\"") }
        return parts.joined(separator: ", ")
    }

    var requestHeaders: [String: String] {
        var headers = [
            "Accept": "application/json",
            "X-Emby-Authorization": authorization,
        ]
        if !token.isEmpty { headers["X-Emby-Token"] = token }
        return headers
    }

    func publicInfo() async throws -> PXMediaServerPublicInfo {
        let data = try await request(path: "/System/Info/Public", authorized: false)
        return try decode(PXMediaServerPublicInfo.self, from: data)
    }

    func login(username: String, password: String) async throws -> PXMediaServerAuthResponse {
        let body: [String: Any] = ["Username": username, "Pw": password]
        let data = try await request(
            path: "/Users/AuthenticateByName",
            method: "POST",
            json: body,
            authorized: false
        )
        return try decode(PXMediaServerAuthResponse.self, from: data)
    }

    func views() async throws -> [PXMediaServerView] {
        struct Response: Decodable { var items: [PXMediaServerView]?; enum CodingKeys: String, CodingKey { case items = "Items" } }
        let data = try await request(path: "/Users/\(userID)/Views")
        return (try decode(Response.self, from: data)).items ?? []
    }

    func items(
        parentID: String?,
        includeTypes: String,
        search: String?,
        start: Int,
        limit: Int,
        sortBy: String = "SortName",
        sortOrder: String = "Ascending"
    ) async throws -> PXMediaServerItemsResponse {
        var query: [URLQueryItem] = [
            .init(name: "Recursive", value: "true"),
            .init(name: "IncludeItemTypes", value: includeTypes),
            .init(name: "Fields", value: "Overview,Genres,PrimaryImageAspectRatio,ProviderIds,MediaSources,MediaStreams,ChildCount,RecursiveItemCount,DateCreated,ProductionYear,RunTimeTicks,OfficialRating,CommunityRating"),
            .init(name: "StartIndex", value: String(max(0, start))),
            .init(name: "Limit", value: String(limit)),
            .init(name: "SortBy", value: sortBy),
            .init(name: "SortOrder", value: sortOrder),
            .init(name: "ImageTypeLimit", value: "1"),
            .init(name: "EnableImageTypes", value: "Primary,Backdrop"),
        ]
        if let parentID, !parentID.isEmpty { query.append(.init(name: "ParentId", value: parentID)) }
        if let search, !search.isEmpty { query.append(.init(name: "SearchTerm", value: search)) }
        let data = try await request(path: "/Users/\(userID)/Items", query: query)
        return try decode(PXMediaServerItemsResponse.self, from: data)
    }

    func item(id: String) async throws -> PXMediaServerItem {
        let data = try await request(
            path: "/Users/\(userID)/Items/\(id)",
            query: [URLQueryItem(name: "Fields", value: "Overview,Genres,ProviderIds,MediaSources,MediaStreams,ChildCount,RecursiveItemCount,DateCreated,ProductionYear,RunTimeTicks,OfficialRating,CommunityRating")]
        )
        return try decode(PXMediaServerItem.self, from: data)
    }

    func episodes(seriesID: String) async throws -> [PXMediaServerItem] {
        let data = try await request(
            path: "/Shows/\(seriesID)/Episodes",
            query: [
                .init(name: "UserId", value: userID),
                .init(name: "Fields", value: "Overview,MediaSources,MediaStreams,PrimaryImageAspectRatio,ProductionYear,RunTimeTicks,OfficialRating,CommunityRating"),
                .init(name: "Limit", value: "500"),
                .init(name: "SortBy", value: "ParentIndexNumber,IndexNumber"),
            ]
        )
        struct Response: Decodable { var items: [PXMediaServerItem]?; enum CodingKeys: String, CodingKey { case items = "Items" } }
        return (try decode(Response.self, from: data)).items ?? []
    }

    func streamURL(itemID: String, mediaSourceID: String?, maxBitrate: Int? = nil) -> URL? {
        guard var components = URLComponents(
            url: baseURL?.appendingPathComponent("Videos/\(itemID)/master.m3u8") ?? URL(fileURLWithPath: "/"),
            resolvingAgainstBaseURL: false
        ) else { return nil }
        var query: [URLQueryItem] = [
            .init(name: "DeviceId", value: configuration.id),
            .init(name: "MediaSourceId", value: mediaSourceID ?? itemID),
            .init(name: "VideoCodec", value: "h264"),
            .init(name: "AudioCodec", value: "aac"),
            .init(name: "TranscodingContainer", value: "ts"),
            .init(name: "TranscodingProtocol", value: "hls"),
            .init(name: "Context", value: "Streaming"),
            .init(name: "api_key", value: token),
        ]
        if let maxBitrate { query.append(.init(name: "MaxStreamingBitrate", value: String(maxBitrate))) }
        components.queryItems = query
        return components.url
    }

    private func request(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        json: [String: Any]? = nil,
        authorized: Bool = true
    ) async throws -> Data {
        guard let baseURL else { throw PXMediaServerError.notConfigured }
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(
            url: baseURL.appendingPathComponent(normalizedPath),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = query.isEmpty ? nil : query
        guard let url = components?.url else { throw PXMediaServerError.transport("URL 拼接失败") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if authorized {
            guard !token.isEmpty else { throw PXMediaServerError.unauthorized }
            requestHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        } else {
            request.setValue(authorization, forHTTPHeaderField: "X-Emby-Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        if let json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw PXMediaServerError.transport("没有 HTTP 响应")
            }
            switch http.statusCode {
            case 200..<300: return data
            case 401, 403: throw PXMediaServerError.unauthorized
            default:
                throw PXMediaServerError.status(http.statusCode, String(data: data.prefix(300), encoding: .utf8))
            }
        } catch let error as PXMediaServerError {
            throw error
        } catch {
            throw PXMediaServerError.transport(error.localizedDescription)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(T.self, from: data) }
        catch { throw PXMediaServerError.decoding(error.localizedDescription) }
    }
}
