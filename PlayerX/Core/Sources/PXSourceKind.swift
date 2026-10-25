import Foundation

/// 一类内容源。站源只是其中之一；后续 CMS、NAS、网盘、Emby 都通过同一套
/// `ContentProvider` 协议接入，UI 不再认识具体协议。
enum PXSourceKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case station
    case jellyfin
    case emby
    case webdav
    case nas
    case alist
    case maccms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .station: "站源"
        case .jellyfin: "Jellyfin"
        case .emby: "Emby"
        case .webdav: "WebDAV"
        case .nas: "NAS"
        case .alist: "Alist / OpenList"
        case .maccms: "MacCMS"
        }
    }

    var symbol: String {
        switch self {
        case .station: "antenna.radiowaves.left.and.right"
        case .jellyfin: "play.tv"
        case .emby: "play.tv.fill"
        case .webdav: "externaldrive.connected.to.line.below"
        case .nas: "externaldrive.fill"
        case .alist: "cloud.fill"
        case .maccms: "server.rack"
        }
    }

    var isMediaServer: Bool { self == .jellyfin || self == .emby }
    var isWebDAV: Bool { self == .webdav || self == .nas || self == .alist }
    var needsCredentials: Bool { isMediaServer || isWebDAV }
    var needsAPIBase: Bool { self == .maccms }

    var defaultPort: Int? {
        switch self {
        case .jellyfin: 8096
        case .emby: 8096
        case .webdav, .nas: 5005
        case .alist: 5244
        default: nil
        }
    }

    var hint: String {
        switch self {
        case .station: "Go 原生核心内置的公开站源"
        case .jellyfin: "Jellyfin 10/12 · 用服务器账号登录"
        case .emby: "Emby Server · 用服务器账号登录"
        case .webdav: "标准 WebDAV，例如群晖 / QNAP / Nextcloud"
        case .nas: "NAS 的 WebDAV 入口，自动识别目录与视频"
        case .alist: "Alist / OpenList 的 /dav 入口，网盘聚合"
        case .maccms: "苹果 CMS / MacCMS 的 provide/vod JSON API"
        }
    }
}
