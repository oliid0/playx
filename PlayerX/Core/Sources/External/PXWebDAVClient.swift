import Foundation

enum PXWebDAVError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case status(Int, String?)
    case parse(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "WebDAV 未配置"
        case .unauthorized: return "WebDAV 认证失败"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "WebDAV HTTP \(code)：\(message)" }
            return "WebDAV HTTP \(code)"
        case .parse: return "WebDAV 目录解析失败"
        case .transport(let message): return message
        }
    }
}

final class PXWebDAVClient {
    let configuration: PXSourceConfiguration
    private let session: URLSession

    init(configuration: PXSourceConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        if let session {
            self.session = session
        } else {
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.timeoutIntervalForRequest = 20
            sessionConfiguration.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: sessionConfiguration)
        }
    }

    var headers: [String: String] {
        [
            "Authorization": PXProviderSupport.basicAuth(
                username: configuration.username,
                password: configuration.password
            ),
            "Accept": "application/xml,text/xml,*/*",
            "User-Agent": "PlayerX/1.0",
        ]
    }

    func rootURL() -> URL? {
        guard let base = configuration.normalizedBaseURL else { return nil }
        let root = configuration.rootPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return root.isEmpty ? base : base.appendingPathComponent(root)
    }

    func listRoot() async throws -> [PXWebDAVEntry] {
        guard let url = rootURL() else { throw PXWebDAVError.notConfigured }
        return try await list(url: url)
    }

    func list(path: String) async throws -> [PXWebDAVEntry] {
        guard let url = absoluteURL(path: path) else { throw PXWebDAVError.notConfigured }
        return try await list(url: url)
    }

    func absoluteURL(path: String) -> URL? {
        if let url = URL(string: path), url.scheme != nil { return url }
        if path.hasPrefix("/") {
            if let base = configuration.normalizedBaseURL,
               let origin = URL(string: "\(base.scheme ?? "https")://\(base.host ?? "")\(base.port.map { ":\($0)" } ?? "")") {
                return URL(string: path, relativeTo: origin)?.absoluteURL
            }
            return configuration.normalizedBaseURL.flatMap { URL(string: path, relativeTo: $0)?.absoluteURL }
        }
        return rootURL()?.appendingPathComponent(path)
    }

    private func list(url: URL) async throws -> [PXWebDAVEntry] {
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = Data("""
        <?xml version="1.0" encoding="utf-8" ?>
        <D:propfind xmlns:D="DAV:">
          <D:prop><D:displayname/><D:resourcetype/><D:getcontentlength/><D:getlastmodified/></D:prop>
        </D:propfind>
        """.utf8)
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw PXWebDAVError.transport("没有 HTTP 响应") }
            switch http.statusCode {
            case 200..<300:
                let entries = PXWebDAVXMLParser().parse(data)
                let selfPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                return entries.filter {
                    let path = ($0.href.removingPercentEncoding ?? $0.href).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    return path != selfPath
                }
            case 401, 403: throw PXWebDAVError.unauthorized
            default:
                throw PXWebDAVError.status(http.statusCode, String(data: data.prefix(250), encoding: .utf8))
            }
        } catch let error as PXWebDAVError {
            throw error
        } catch {
            throw PXWebDAVError.transport(error.localizedDescription)
        }
    }
}
