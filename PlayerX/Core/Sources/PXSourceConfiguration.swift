import Foundation

/// 用户添加的外部媒体源。站源是内置的，不落这份配置。
struct PXSourceConfiguration: Codable, Identifiable, Hashable {
    var id: String
    var kind: PXSourceKind
    var name: String
    var baseURL: String
    var username: String
    var password: String
    var token: String
    var userID: String
    var serverID: String
    var rootPath: String
    var apiPath: String
    var enabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        kind: PXSourceKind,
        name: String = "",
        baseURL: String = "",
        username: String = "",
        password: String = "",
        token: String = "",
        userID: String = "",
        serverID: String = "",
        rootPath: String = "/",
        apiPath: String = "api.php/provide/vod/",
        enabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.baseURL = baseURL
        self.username = username
        self.password = password
        self.token = token
        self.userID = userID
        self.serverID = serverID
        self.rootPath = rootPath
        self.apiPath = apiPath
        self.enabled = enabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let host = URL(string: baseURL)?.host { return "\(kind.title) · \(host)" }
        return kind.title
    }

    var normalizedBaseURL: URL? {
        var raw = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if !raw.contains("://") { raw = "https://\(raw)" }
        while raw.hasSuffix("/") { raw.removeLast() }
        return URL(string: raw)
    }

    var isConfigured: Bool {
        guard let url = normalizedBaseURL else { return false }
        if kind.isMediaServer { return !userID.isEmpty && !token.isEmpty && url.host != nil }
        if kind.isWebDAV { return url.host != nil && !username.isEmpty }
        if kind == .maccms { return url.host != nil }
        return false
    }

    mutating func touch() { updatedAt = Date() }
}
