import Foundation
import CoreGraphics

struct PXPlaybackStats: Equatable {
    var engine: PXPlayerEngineKind
    var state: PXPlaybackState
    var currentTime: Double
    var duration: Double
    var buffered: Double
    var videoSize: CGSize
    var audioTracks: Int
    var subtitleTracks: Int
    var rate: Double
    var isPortrait: Bool
    var danmakuCount: Int

    init(engine: PXPlayerEngineKind, snapshot: PXPlayerSnapshot, danmakuCount: Int) {
        self.engine = engine
        self.state = snapshot.state
        self.currentTime = snapshot.currentTime
        self.duration = snapshot.duration
        self.buffered = snapshot.buffered
        self.videoSize = snapshot.videoSize
        self.audioTracks = snapshot.audioTracks.count
        self.subtitleTracks = snapshot.subtitleTracks.count
        self.rate = snapshot.rate
        self.isPortrait = snapshot.isPortraitVideo
        self.danmakuCount = danmakuCount
    }

    var progress: Double { duration > 0 ? min(max(currentTime / duration, 0), 1) : 0 }
    var resolutionText: String {
        videoSize == .zero ? "—" : "\(Int(videoSize.width)) × \(Int(videoSize.height))"
    }
}
