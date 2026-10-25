import Foundation

extension Drama {
    init(
        id: String,
        source: String,
        sourceId: String,
        title: String,
        description: String? = nil,
        cover: String? = nil,
        episodes: Int? = nil,
        category: String? = nil,
        vip: Bool? = false,
        heat: String? = nil,
        views: String? = nil,
        onlineDate: String? = nil,
        tags: [String]? = nil,
        releaseStatus: String? = nil
    ) {
        self.init(
            metadataSchema: nil,
            id: id,
            source: source,
            sourceId: sourceId,
            title: title,
            description: description,
            cover: cover,
            episodes: episodes,
            category: category,
            vip: vip,
            heat: heat,
            views: views,
            onlineDate: onlineDate,
            tags: tags,
            releaseStatus: releaseStatus
        )
    }
}

extension Chapter {
    init(
        id: String,
        source: String?,
        title: String,
        videoUrl: String,
        currentEpisode: String? = nil,
        mediaSize: Int64? = nil,
        pageUrl: String? = nil,
        referer: String? = nil,
        vip: Bool? = false
    ) {
        self.vip = vip
        self.id = id
        self.source = source
        self.title = title
        self.videoUrl = videoUrl
        self.currentEpisode = currentEpisode
        self.mediaSize = mediaSize
        self.pageUrl = pageUrl
        self.referer = referer
    }
}

extension PlaybackPlan {
    init(
        url: String,
        headers: [String: String]? = nil,
        decryptionKey: String? = nil,
        quality: Int? = nil,
        qualities: [Int]? = nil,
        session: String? = nil,
        local: Bool? = false,
        danmakuId: String? = nil,
        expiresAt: Int64? = nil,
        prefetchedBytes: Int64? = nil,
        routeIndex: Int? = nil,
        routeCount: Int? = nil
    ) {
        self.init(
            url: url,
            headers: headers,
            decryptionKey: decryptionKey,
            quality: quality,
            qualities: qualities,
            session: session,
            local: local,
            danmakuId: danmakuId,
            expiresAt: expiresAt,
            prefetchedBytes: prefetchedBytes,
            routeIndex: routeIndex,
            routeCount: routeCount
        )
    }
}

enum PXProviderSupport {
    static let videoExtensions: Set<String> = [
        "mp4", "m4v", "mov", "mkv", "webm", "avi", "ts", "m3u8", "flv", "wmv", "mpg", "mpeg",
    ]

    static func isVideo(path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return videoExtensions.contains(ext)
    }

    static func fileName(path: String) -> String {
        let decoded = path.removingPercentEncoding ?? path
        let name = (decoded as NSString).lastPathComponent
        return name.isEmpty ? decoded : (name as NSString).deletingPathExtension
    }

    static func stripHTML(_ raw: String?) -> String? {
        guard let raw else { return nil }
        var value = raw.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        value = value.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: "&nbsp;", with: " ")
        value = value.replacingOccurrences(of: "&amp;", with: "&")
        value = value.replacingOccurrences(of: "&lt;", with: "<")
        value = value.replacingOccurrences(of: "&gt;", with: ">")
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func basicAuth(username: String, password: String) -> String {
        "Basic " + Data("\(username):\(password)".utf8).base64EncodedString()
    }

    static func mediaKind(title: String, genres: [String], library: String?) -> PXMediaKind {
        let haystack = ([title, library ?? ""] + genres).joined(separator: " ").lowercased()
        if haystack.contains("anime") || haystack.contains("动漫") || haystack.contains("动画")
            || haystack.contains("番剧") {
            return .anime
        }
        if haystack.contains("documentary") || haystack.contains("纪录") { return .documentary }
        if haystack.contains("variety") || haystack.contains("综艺") { return .variety }
        if haystack.contains("movie") || haystack.contains("电影") { return .movie }
        return .series
    }
}
