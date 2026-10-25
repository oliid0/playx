import Foundation

/// TMDB v3 客户端（Bearer v4 token）。内置 token 由 `PXAppSettings` 提供，
/// 用户换 Key 后立即生效。所有请求都走 20 秒超时 + 429 Retry-After 重试。
actor PXTMDbClient {
    static let baseURL = URL(string: "https://api.themoviedb.org/3")!

    private let session: URLSession
    private let decoder: JSONDecoder
    private var lastRequestAt: Date = .distantPast

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 30
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func search(
        query: String,
        kind: PXMediaKind,
        year: Int?,
        language: String,
        token: String,
        page: Int = 1
    ) async throws -> [PXTMDbSearchResult] {
        let path: String
        switch kind {
        case .movie: path = "search/movie"
        case .series, .anime, .shortDrama, .variety, .documentary: path = "search/tv"
        }
        var items: [URLQueryItem] = [
            .init(name: "query", value: query),
            .init(name: "language", value: language),
            .init(name: "page", value: String(page)),
            .init(name: "include_adult", value: "false"),
        ]
        if let year {
            items.append(.init(name: kind == .movie ? "year" : "first_air_date_year", value: String(year)))
        }
        let response: PXTMDbSearchResponse = try await get(
            path: path, query: items, token: token, language: language)
        return (response.results ?? []).map { item in
            var copy = item
            if copy.mediaType == nil {
                copy.mediaType = kind == .movie ? "movie" : "tv"
            }
            return copy
        }
    }

    func multiSearch(query: String, language: String, token: String) async throws -> [PXTMDbSearchResult] {
        let items: [URLQueryItem] = [
            .init(name: "query", value: query),
            .init(name: "language", value: language),
            .init(name: "include_adult", value: "false"),
        ]
        let response: PXTMDbSearchResponse = try await get(
            path: "search/multi", query: items, token: token, language: language)
        return response.results ?? []
    }

    func detail(tmdbID: Int, kind: PXMediaKind, language: String, token: String) async throws -> PXTMDbDetailDTO {
        let path = kind == .movie ? "movie/\(tmdbID)" : "tv/\(tmdbID)"
        let append = "credits,images,external_ids,content_ratings,videos,recommendations,similar,release_dates"
        let items = [URLQueryItem(name: "append_to_response", value: append)]
        var detail: PXTMDbDetailDTO = try await get(path: path, query: items, token: token, language: language)
        if (detail.overview ?? "").isEmpty || (detail.title ?? detail.name ?? "").isEmpty {
            if let fallback: PXTMDbDetailDTO = try? await get(
                path: path, query: items, token: token, language: "en-US"
            ) {
                if (detail.overview ?? "").isEmpty { detail.overview = fallback.overview }
                if (detail.title ?? "").isEmpty { detail.title = fallback.title }
                if (detail.name ?? "").isEmpty { detail.name = fallback.name }
            }
        }
        return detail
    }

    func season(
        tvID: Int,
        seasonNumber: Int,
        language: String,
        token: String
    ) async throws -> PXTMDbSeasonDetail {
        try await get(
            path: "tv/\(tvID)/season/\(seasonNumber)",
            query: [URLQueryItem(name: "language", value: language)],
            token: token,
            language: language
        )
    }

    func trending(window: String = "week", language: String, token: String) async throws -> [PXTMDbSearchResult] {
        let response: PXTMDbSearchResponse = try await get(
            path: "trending/all/\(window)",
            query: [URLQueryItem(name: "language", value: language)],
            token: token,
            language: language
        )
        return response.results ?? []
    }

    func discover(kind: PXMediaKind, genreID: Int?, language: String, token: String, page: Int = 1) async throws -> [PXTMDbSearchResult] {
        let path = kind == .movie ? "discover/movie" : "discover/tv"
        var query = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "vote_count.gte", value: "20"),
        ]
        if let genreID { query.append(.init(name: "with_genres", value: String(genreID))) }
        let response: PXTMDbSearchResponse = try await get(path: path, query: query, token: token, language: language)
        return (response.results ?? []).map { item in
            var copy = item
            copy.mediaType = kind == .movie ? "movie" : "tv"
            return copy
        }
    }

    private func get<T: Decodable>(
        path: String,
        query: [URLQueryItem],
        token: String,
        language: String
    ) async throws -> T {
        guard !token.isEmpty else { throw PXTMDbError.notConfigured }
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = query
        guard let url = components?.url else { throw PXTMDbError.transport("URL 拼接失败") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data = try await perform(request)
        do { return try decoder.decode(T.self, from: data) }
        catch { throw PXTMDbError.decoding(error.localizedDescription) }
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        // 轻微节流，避免首页并发把免费额度瞬间打满。
        let elapsed = Date().timeIntervalSince(lastRequestAt)
        if elapsed < 0.04 {
            try? await Task.sleep(nanoseconds: UInt64((0.04 - elapsed) * 1_000_000_000))
        }
        lastRequestAt = Date()

        for attempt in 0..<3 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw PXTMDbError.transport("没有 HTTP 响应")
                }
                switch http.statusCode {
                case 200..<300:
                    return data
                case 401:
                    throw PXTMDbError.unauthorized
                case 404:
                    throw PXTMDbError.notFound
                case 429:
                    let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init)
                    if attempt < 2 {
                        let delay = min(retryAfter ?? 1.2, 4)
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                    throw PXTMDbError.rateLimited(retryAfter: retryAfter)
                default:
                    if (500...599).contains(http.statusCode), attempt < 2 {
                        try? await Task.sleep(nanoseconds: UInt64((0.5 * Double(attempt + 1)) * 1_000_000_000))
                        continue
                    }
                    throw PXTMDbError.status(http.statusCode)
                }
            } catch let error as PXTMDbError {
                throw error
            } catch let error as URLError where error.code == .cancelled {
                throw PXTMDbError.cancelled
            } catch {
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    continue
                }
                throw PXTMDbError.transport(error.localizedDescription)
            }
        }
        throw PXTMDbError.transport("请求重试次数耗尽")
    }
}
