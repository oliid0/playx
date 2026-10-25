import Foundation

enum PXTMDbError: Error, LocalizedError {
    case notConfigured
    case unauthorized
    case rateLimited(retryAfter: Double?)
    case notFound
    case status(Int)
    case decoding(String)
    case transport(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured: "TMDB 未配置"
        case .unauthorized: "TMDB 访问令牌无效"
        case .rateLimited: "TMDB 请求过于频繁"
        case .notFound: "TMDB 上没有这个条目"
        case .status(let code): "TMDB HTTP \(code)"
        case .decoding: "TMDB 响应无法解析"
        case .transport(let message): message
        case .cancelled: "请求已取消"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .rateLimited, .transport: true
        default: false
        }
    }
}
