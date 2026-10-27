import Foundation

enum PXUQueryBuilder {
    static func string(_ items: [(String, String)]) -> String {
        items
            .map { key, value in
                let escaped = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(key)=\(escaped)"
            }
            .joined(separator: "&")
    }
}
