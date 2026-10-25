import Foundation
enum PXURLScheme {
    static let scheme = "playerx"
    static func detail(source: String, id: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "detail"
        components.queryItems = [URLQueryItem(name: "source", value: source), URLQueryItem(name: "id", value: id)]
        return components.url
    }
    static func player(url: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "player"
        components.queryItems = [URLQueryItem(name: "url", value: url)]
        return components.url
    }
}
