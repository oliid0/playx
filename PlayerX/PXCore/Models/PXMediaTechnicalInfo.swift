import Foundation

/// 详情页“媒体信息”卡片。值全部是展示用字符串，UI 不再做单位换算。
struct PXMediaTechnicalInfo: Codable, Hashable, Sendable {
    var source: String?
    var quality: String?
    var container: String?
    var videoCodec: String?
    var audioCodec: String?
    var resolution: String?
    var bitrate: String?
    var fileSize: String?
    var audioTracks: [String] = []
    var subtitleTracks: [String] = []
    var dynamicRange: String?

    var isEmpty: Bool {
        quality == nil && container == nil && videoCodec == nil && resolution == nil
            && bitrate == nil && fileSize == nil && audioTracks.isEmpty && subtitleTracks.isEmpty
    }

    var rows: [(String, String)] {
        [
            ("清晰度", quality),
            ("容器", container),
            ("视频", videoCodec),
            ("音频", audioCodec),
            ("分辨率", resolution),
            ("码率", bitrate),
            ("大小", fileSize),
            ("动态范围", dynamicRange),
        ].compactMap { title, value in
            guard let value, !value.isEmpty else { return nil }
            return (title, value)
        }
    }

    static func from(plan: PlaybackPlan?, chapter: Chapter?) -> PXMediaTechnicalInfo {
        var info = PXMediaTechnicalInfo()
        if let size = chapter?.mediaSize, size > 0 {
            info.fileSize = PXFormat.byteCount(size)
        }
        if let quality = plan?.quality, quality > 0 {
            info.quality = PlaybackPreferences.qualityTitle(quality)
            info.resolution = "\(quality)P"
        }
        if let url = plan?.url.lowercased(), url.contains(".m3u8") {
            info.container = "HLS"
            info.videoCodec = "H.264 / HEVC"
            info.audioCodec = "AAC"
        }
        return info
    }
}
