import Foundation

enum PXMacCMSError: Error, LocalizedError {
    case notConfigured
    case status(Int, String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "MacCMS 源未配置"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "MacCMS HTTP \(code)：\(message)" }
            return "MacCMS HTTP \(code)"
        case .decoding: return "MacCMS 响应无法解析"
        case .transport(let message): return message
        }
    }
}

final class PXMacCMSClient {
    let configuration: PXSourceConfiguration
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(configuration: PXSourceConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = 18
            sessionConfiguration.timeoutIntervalForResource = 35
            self.session = URLSession(configuration: sessionConfiguration)
        }
    }

    var headers: [String: String] {
        [
            "Accept": "application/json,text/plain,*/*",
            "User-Agent": PXProviderSupport.userAgent,
            "Referer": configuration.normalizedBaseURL?.absoluteString ?? "",
        ]
    }

    func categories() async throws -> [SourceCategory] {
        var response = try await fetch(["ac": "list"])
        if response.categories?.isEmpty != false {
            response = try await fetch(["ac": "detail", "pg": "1"])
        }
        let classes = response.categories ?? []
        return classes.map { SourceCategory(id: $0.id, name: $0.name) }
    }

    func items(category: String, page: Int, query: String?) async throws -> PXMacCMSResponse {
        var params: [String: String] = [
            "ac": "detail",
            "pg": String(max(1, page)),
        ]
        if !category.isEmpty { params["t"] = category }
        if let query, !query.isEmpty { params["wd"] = query }
        do {
            let response = try await fetch(params)
            if let list = response.list, !list.isEmpty { return response }
        } catch {
            // 一些老 MacCMS 只认 videolist，继续尝试。
        }
        params["ac"] = "videolist"
        return try await fetch(params)
    }

    func item(id: String) async throws -> PXMacCMSItem? {
        var response = try await fetch(["ac": "detail", "ids": id])
        if response.list?.isEmpty != false {
            response = try await fetch(["ac": "videolist", "ids": id])
        }
        return response.list?.first
    }

    private func fetch(_ params: [String: String]) async throws -> PXMacCMSResponse {
        guard let base = configuration.normalizedBaseURL else { throw PXMacCMSError.notConfigured }
        let apiPath = configuration.apiPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = apiPath.isEmpty ? base : base.appendingPathComponent(apiPath)
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { throw PXMacCMSError.transport("URL 拼接失败") }
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw PXMacCMSError.transport("没有 HTTP 响应") }
            guard (200..<300).contains(http.statusCode) else {
                throw PXMacCMSError.status(http.statusCode, String(data: data.prefix(250), encoding: .utf8))
            }
            do { return try decoder.decode(PXMacCMSResponse.self, from: data) }
            catch { throw PXMacCMSError.decoding(error.localizedDescription) }
        } catch let error as PXMacCMSError {
            throw error
        } catch {
            throw PXMacCMSError.transport(error.localizedDescription)
        }
    }
}
