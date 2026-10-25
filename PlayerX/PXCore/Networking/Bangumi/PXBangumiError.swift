import Foundation

enum PXBangumiError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case notFound
    case status(Int, String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Bangumi 尚未登录"
        case .unauthorized: return "Bangumi 令牌失效，请重新登录"
        case .notFound: return "Bangumi 上没有这个条目"
        case .status(let code, let message):
            if let message, !message.isEmpty { return "Bangumi HTTP \(code)：\(message)" }
            return "Bangumi HTTP \(code)"
        case .decoding: return "Bangumi 响应无法解析"
        case .transport(let message): return message
        }
    }
}
