import Foundation
enum PXEndpointValidator {
    static func normalized(_ raw: String) -> URL? {
        let value = raw.pxTrimmed
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) {
            return url
        }
        return URL(string: "https://\(value)")
    }
    static func isSecure(_ url: URL?) -> Bool { url?.scheme?.lowercased() == "https" }
}
