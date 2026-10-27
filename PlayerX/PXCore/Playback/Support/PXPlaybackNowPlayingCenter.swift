import Foundation
import MediaPlayer

/// 锁屏 / 控制中心 / macOS Now Playing 的统一入口。播放器每次状态变化节流更新，
/// 不依赖具体播放内核。
@MainActor
enum PXPlaybackNowPlayingCenter {
    static func update(
        drama: Drama,
        chapter: Chapter?,
        duration: Double,
        elapsed: Double,
        rate: Double,
        isPlaying: Bool
    ) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: drama.title,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? rate : 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, elapsed),
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue,
        ]
        if let chapter, !chapter.title.isEmpty {
            info[MPMediaItemPropertyAlbumTitle] = chapter.title
        }
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    static func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
}
