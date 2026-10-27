import Foundation

enum PXUBasicAuth {
    static func header(username: String, password: String) -> String {
        let raw = "\(username):\(password)"
        return "Basic " + Data(raw.utf8).base64EncodedString()
    }
}
