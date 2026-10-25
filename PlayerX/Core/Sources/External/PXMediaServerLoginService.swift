import Foundation

struct PXSourceTestResult {
    var title: String
    var detail: String
}

enum PXSourceLoginService {
    static func authenticate(_ configuration: PXSourceConfiguration) async throws -> PXSourceConfiguration {
        guard configuration.kind.isMediaServer else { return configuration }
        var updated = configuration
        guard let baseURL = configuration.normalizedBaseURL else {
            throw PXMediaServerError.notConfigured
        }
        updated.baseURL = baseURL.absoluteString
        let client = PXMediaServerClient(configuration: updated)
        let info = try await client.publicInfo()
        let auth = try await client.login(username: configuration.username, password: configuration.password)
        guard let token = auth.accessToken, let user = auth.user else {
            throw PXMediaServerError.unauthorized
        }
        updated.token = token
        updated.userID = user.id
        updated.serverID = auth.serverId ?? info.id ?? ""
        if updated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.name = info.serverName ?? "\(configuration.kind.title) · \(baseURL.host ?? "")"
        }
        updated.touch()
        return updated
    }

    static func test(_ configuration: PXSourceConfiguration) async throws -> PXSourceTestResult {
        switch configuration.kind {
        case .jellyfin, .emby:
            guard let baseURL = configuration.normalizedBaseURL else { throw PXMediaServerError.notConfigured }
            var probe = configuration
            probe.baseURL = baseURL.absoluteString
            let client = PXMediaServerClient(configuration: probe)
            let info = try await client.publicInfo()
            if !configuration.username.isEmpty {
                let updated = try await authenticate(probe)
                return PXSourceTestResult(
                    title: info.serverName ?? updated.name,
                    detail: "登录成功 · \(info.version ?? "未知版本")"
                )
            }
            return PXSourceTestResult(title: info.serverName ?? "媒体服务器", detail: "连接成功 · \(info.version ?? "")")
        case .webdav, .nas, .alist:
            let entries = try await PXWebDAVClient(configuration: configuration).list(path: configuration.rootPath)
            return PXSourceTestResult(title: "WebDAV 连接成功", detail: "\(entries.count) 个项目")
        case .maccms:
            let categories = try await PXMacCMSClient(configuration: configuration).categories()
            return PXSourceTestResult(title: "MacCMS 连接成功", detail: "\(categories.count) 个分类")
        case .station:
            return PXSourceTestResult(title: "内置站源", detail: "无需配置")
        }
    }
}
