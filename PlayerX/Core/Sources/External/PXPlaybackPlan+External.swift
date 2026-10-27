import Foundation

extension PlaybackPlan {
    /// 外部源专用初始化器。刻意使用 `streamURL` 标签，避免与 Codable 结构体的
    /// memberwise initializer 重名（Swift 会把同签名的 extension init 视为重声明）。
    init(
        streamURL: String,
        headers: [String: String]? = nil,
        quality: Int? = nil,
        qualities: [Int]? = nil
    ) {
        self.url = streamURL
        self.directURL = streamURL
        self.headers = headers
        self.decryptionKey = nil
        self.quality = quality
        self.qualities = qualities
        self.session = nil
        self.local = false
        self.danmakuId = nil
        self.expiresAt = nil
        self.prefetchedBytes = nil
        self.routeIndex = nil
        self.routeCount = nil
    }
}
