import Foundation

enum PXDanmakuError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case rateLimited
    case noMatch
    case status(Int, String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "弹幕网关未配置"
        case .unauthorized: "弹幕网关校验失败"
        case .rateLimited: "弹幕请求过于频繁"
        case .noMatch: "没有找到匹配的弹幕"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "弹幕 HTTP \(code)：\(message)" }
            return "弹幕 HTTP \(code)"
        case .decoding: "弹幕响应无法解析"
        case .transport(let message): message
        }
    }
}

/// 弹弹play 只读网关。用内置公共 Key 开箱即用，设置里可换成自建网关。
actor PXDanmakuClient {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 18
            configuration.timeoutIntervalForResource = 30
            configuration.httpAdditionalHeaders = [
                "User-Agent": "OcPlay/1.0 (PlayerX; iOS)",
                "Accept": "application/json",
            ]
            self.session = URLSession(configuration: configuration)
        }
    }

    func episodes(
        title: String,
        episodeNumber: Int,
        gateway: URL,
        apiKey: String
    ) async throws -> PXDanmakuEpisode? {
        guard !apiKey.isEmpty else { throw PXDanmakuError.notConfigured }
        let query = [
            URLQueryItem(name: "anime", value: title),
            URLQueryItem(name: "episode", value: String(episodeNumber)),
        ]
        let data = try await request(
            url: gateway.appendingPathComponent("v1/search/episodes"),
            query: query,
            apiKey: apiKey
        )
        let response: PXDanmakuSearchResponse = try decode(data)
        guard let animes = response.animes, !animes.isEmpty else { throw PXDanmakuError.noMatch }

        let scored = animes.compactMap { anime -> (PXDanmakuEpisode, Double)? in
            guard let episode = anime.episodes?.first else { return nil }
            let score = PXNormalizer.similarity(title, anime.animeTitle ?? "")
            return (
                PXDanmakuEpisode(
                    episodeID: episode.episodeID,
                    animeID: anime.animeID,
                    animeTitle: anime.animeTitle,
                    episodeTitle: episode.episodeTitle
                ),
                score
            )
        }
        return scored.max { $0.1 < $1.1 }?.0
    }

    func comments(
        episodeID: Int64,
        gateway: URL,
        apiKey: String
    ) async throws -> [PXDanmakuComment] {
        let data = try await request(
            url: gateway.appendingPathComponent("v1/comments/\(episodeID)"),
            query: [],
            apiKey: apiKey
        )
        let response: PXDanmakuCommentsResponse = try decode(data)
        let raw = response.comments ?? []
        return raw.enumerated().compactMap { index, item in
            PXDanmakuComment(raw: item, index: index)
        }
    }

    private func request(url: URL, query: [URLQueryItem], apiKey: String) async throws -> Data {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = query.isEmpty ? nil : query
        guard let finalURL = components?.url else { throw PXDanmakuError.transport("URL 拼接失败") }
        var request = URLRequest(url: finalURL)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("OcPlay/1.0 (PlayerX; iOS)", forHTTPHeaderField: "User-Agent")
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw PXDanmakuError.transport("没有 HTTP 响应")
                }
                switch http.statusCode {
                case 200..<300: return data
                case 401, 403: throw PXDanmakuError.unauthorized
                case 429:
                    if attempt < 2 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw PXDanmakuError.rateLimited
                default:
                    throw PXDanmakuError.status(http.statusCode, String(data: data.prefix(200), encoding: .utf8))
                }
            } catch let error as PXDanmakuError {
                throw error
            } catch {
                lastError = error
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    continue
                }
            }
        }
        throw PXDanmakuError.transport(lastError?.localizedDescription ?? "弹幕请求失败")
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do { return try decoder.decode(T.self, from: data) }
        catch { throw PXDanmakuError.decoding(error.localizedDescription) }
    }
}
