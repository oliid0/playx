import Foundation
enum PXTokenMask {
    static func mask(_ token: String) -> String {
        guard token.count > 8 else { return token.isEmpty ? "未设置" : "••••" }
        return "\(token.prefix(4))••••\(token.suffix(4))"
    }
    static func looksLikeJWT(_ token: String) -> Bool {
        token.split(separator: ".").count == 3
    }
}
