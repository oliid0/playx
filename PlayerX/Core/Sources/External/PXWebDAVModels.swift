import Foundation

struct PXWebDAVEntry: Hashable {
    var href: String
    var name: String
    var isDirectory: Bool
    var contentLength: Int64?
    var modifiedAt: String?

    var url: URL? {
        guard let url = URL(string: href) else { return nil }
        return url
    }

    var decodedName: String {
        let value = name.removingPercentEncoding ?? name
        return value.isEmpty ? (href as NSString).lastPathComponent : value
    }
}
