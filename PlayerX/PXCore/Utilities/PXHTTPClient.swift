import Foundation

enum PXHTTPError: Error, LocalizedError {
    case invalidURL
    case status(Int, String?)
    case transport(String)
    case decoding(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL: "地址无效"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "HTTP \(code)：\(message)" }
            return "HTTP \(code)"
        case .transport(let message): message
        case .decoding(let message): "响应解析失败：\(message)"
        case .cancelled: "请求已取消"
        }
    }
}

actor PXHTTPClient {
    static let shared = PXHTTPClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 40
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.httpAdditionalHeaders = ["Accept": "application/json"]
            self.session = URLSession(configuration: configuration)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func data(for request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw PXHTTPError.transport("没有收到 HTTP 响应") }
            guard (200..<300).contains(http.statusCode) else {
                let message = String(data: data.prefix(500), encoding: .utf8)
                throw PXHTTPError.status(http.statusCode, message)
            }
            return data
        } catch let error as PXHTTPError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw PXHTTPError.cancelled
        } catch {
            throw PXHTTPError.transport(error.localizedDescription)
        }
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) }
        catch { throw PXHTTPError.decoding(error.localizedDescription) }
    }

    func get<T: Decodable>(_ type: T.Type, url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let data = try await data(for: request)
        return try decode(type, from: data)
    }

    func post<T: Decodable, B: Encodable>(
        _ type: T.Type,
        url: URL,
        body: B,
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONEncoder().encode(body)
        let data = try await data(for: request)
        return try decode(type, from: data)
    }
}
