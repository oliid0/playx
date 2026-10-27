import Foundation

/// 对应 Go 侧 `nativeDrama`（native/core/app_runtime.go）。字段名已经是各站源归一化后的结果，
/// `id` 形如 `"hongguo:7123456"`（`<source>:<sourceId>`），封面已经是校验过的 http(s) 直链。
struct Drama: Codable, Identifiable, Hashable {
    var metadataSchema: Int?
    var id: String
    var source: String
    var sourceId: String
    var title: String
    var description: String?
    var cover: String?
    var episodes: Int?
    var category: String?
    var vip: Bool?
    var heat: String?
    var views: String?
    var onlineDate: String?
    var tags: [String]?
    var releaseStatus: String?
}

/// 对应 Go 侧 `Chapter`（native/core/models.go）。`currentEpisode` 在 Go 里是 `json.RawMessage`，
/// 不同站源分别给字符串/整数/浮点/null，这里手写解码成统一的 `String?`。
struct Chapter: Codable, Hashable {
    var vip: Bool?
    var id: String
    var source: String?
    var title: String
    var videoUrl: String
    var currentEpisode: String?
    var mediaSize: Int64?
    var pageUrl: String?
    var referer: String?

    enum CodingKeys: String, CodingKey {
        case vip, id, source, title, videoUrl, currentEpisode, mediaSize, pageUrl, referer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vip = try container.decodeIfPresent(Bool.self, forKey: .vip)
        id = try container.decode(String.self, forKey: .id)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        title = try container.decode(String.self, forKey: .title)
        videoUrl = try container.decode(String.self, forKey: .videoUrl)
        mediaSize = try container.decodeIfPresent(Int64.self, forKey: .mediaSize)
        pageUrl = try container.decodeIfPresent(String.self, forKey: .pageUrl)
        referer = try container.decodeIfPresent(String.self, forKey: .referer)
        // 用 decode（不是 decodeIfPresent）+ try?：键缺失/值为 null/类型不符都会被 try? 吃成 nil，
        // 逐个类型试过去。注意 decodeIfPresent 包 try? 会被 Swift 5 的 optional-flattening
        // (SE-0230) 拍成单层 Optional，if let 会直接解到裸值，根本拿不到 .map 用——CI 编译时
        // 真的因为这个报过 "value of type 'Int' has no member 'map'"，这里就是那次修复。
        if let text = try? container.decode(String.self, forKey: .currentEpisode) {
            currentEpisode = text
        } else if let number = try? container.decode(Int.self, forKey: .currentEpisode) {
            currentEpisode = String(number)
        } else if let number = try? container.decode(Double.self, forKey: .currentEpisode) {
            currentEpisode = String(Int(number))
        } else {
            currentEpisode = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vip, forKey: .vip)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encode(title, forKey: .title)
        try container.encode(videoUrl, forKey: .videoUrl)
        try container.encodeIfPresent(currentEpisode, forKey: .currentEpisode)
        try container.encodeIfPresent(mediaSize, forKey: .mediaSize)
        try container.encodeIfPresent(pageUrl, forKey: .pageUrl)
        try container.encodeIfPresent(referer, forKey: .referer)
    }
}

/// 对应 Go 侧 `nativeCategory`（native/core/app_categories.go）。`id` 为空字符串的那一条是"全部"。
struct SourceCategory: Codable, Identifiable, Hashable {
    var id: String
    var name: String
}

/// `catalog` action 的响应（对应 Go 侧 `nativeCatalogResult`）。
struct CatalogResult: Codable {
    var items: [Drama]
    var hasMore: Bool
    var page: Int
    var warning: String?
    var localSearch: Bool?
    var fresh: Bool?
}

/// `detail` action 的响应。
struct DetailResult: Codable {
    var drama: Drama
    var chapters: [Chapter]
    var warning: String?
}

/// `resolve`/`localPlayback` action的响应（对应 Go 侧 `nativePlan`）：播放直链 + 必要的请求头/解密信息。
///
/// `url` 对在线播放来说不是站源原始直链，而是 Go 核心内嵌的本机回环代理
/// （`native/core/app_stream.go` 的 `nativeStreamServer`，监听 `127.0.0.1:随机端口`）吐出来的地址——
/// 它会把标准 HLS AES-128 的密钥 URI 重写指向自己再原样把密钥吐回去，AVPlayer 原生就认得这种
/// HLS 解密，不用自己写 `AVAssetResourceLoaderDelegate`。`headers` 是喂给这个本机代理内部去请求
/// 真实 CDN 用的，AVPlayer 这边其实用不上，留着传一份无害。
/// `decryptionKey`（CENC，非标准 HLS 密钥那种）本机代理不处理，这类内容 AVPlayer 播不了，
/// 见 Documentation/Architecture.md「已知限制」。
struct PlaybackPlan: Codable {
    var url: String
    var directURL: String?
    var headers: [String: String]?
    var decryptionKey: String?
    var quality: Int?
    var qualities: [Int]?
    var session: String?
    var local: Bool?
    var danmakuId: String?
    var expiresAt: Int64?
    var prefetchedBytes: Int64?
    var routeIndex: Int?
    var routeCount: Int?
}

/// `enqueueDownloads`请求里的一条分集（对应 Go 侧 `nativeDownloadEpisode`）。
struct DownloadEntry: Encodable {
    var chapter: Chapter
    var index: Int
}

/// `downloads` action 的响应条目（对应 Go 侧 `nativeDownloadJob`）。下载调度、断点续传、HLS 分片/
/// 密钥改写全部在 Go 核心里，Swift 这边只发控制指令、轮询这个状态，不碰文件本身。
struct DownloadJob: Codable, Identifiable, Hashable {
    var id: String
    var drama: Drama
    var chapter: Chapter
    var index: Int
    var quality: Int?
    var actualQuality: Int?
    var state: String
    var archived: Bool?
    var folder: String?
    var bytes: Int64
    var total: Int64
    var progress: Double
    var error: String?
    var created: Int64
    var revision: Int64?

    static let stateQueued = "queued"
    static let stateDownloading = "downloading"
    static let statePaused = "paused"
    static let stateFailed = "failed"
    static let stateCompleted = "completed"
    static let stateRemoving = "removing"
}

/// `danmaku` action 响应的一条弹幕（对应 Go 侧 `hongguoDanmakuItem`）。只有红果在线播放支持，
/// 且要先 `resolve` 拿到 `PlaybackPlan.danmakuId`/`session` 才能请求。
struct DanmakuItem: Codable, Identifiable, Hashable {
    var id: String
    var text: String
    var timeMs: Int64
}

/// 对应 Go 侧 `hongguoDanmakuPage`：按时间窗口分页返回。
struct DanmakuPage: Codable {
    var episodeId: String
    var items: [DanmakuItem]
    var startMs: Int64
    var nextMs: Int64
    var total: Int64
}

/// `cover` action 的响应：Go 核心已经把封面下载到本地文件（带正确的 Referer，有磁盘缓存），
/// 返回的是本机文件路径，不是继续给一个 URL。`heic` 是 Flutter 那边要不要额外转码的信号，
/// iOS 的 `UIImage`/`CGImageSource` 原生就能读 HEIC，用不上。
struct CoverResult: Decodable {
    var path: String
    var heic: Bool
}
