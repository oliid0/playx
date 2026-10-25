import Foundation

/// 红果在线播放的弹幕。调用方必须先 `resolve` 拿到 `PlaybackPlan`，`danmakuId` 非空时才有弹幕，
/// 拉取要带 `PlaybackPlan.session`（Go 侧叫 `playbackSession`，和 `release`/`cancelPlayback`
/// 用的 `session` 字段不是一回事，别搞混）。
///
/// Go 核心限制一次最多拉 24 小时窗口，但按 30 秒一段增量拉取更接近原版体验（不用一次性
/// 把整集弹幕都下载下来），`DanmakuOverlay` 播放时按这个节奏自己往后翻页。
enum DanmakuClient {
    static let windowMs: Int64 = 30_000

    static func fetchWindow(playbackSession: String, startMs: Int64, durationMs: Int64 = windowMs) async throws -> DanmakuPage {
        try await NativeBridge.call(
            NativeRequest(action: "danmaku", playbackSession: playbackSession,
                          startMs: startMs, durationMs: durationMs)
        )
    }
}
