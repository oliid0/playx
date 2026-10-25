import Foundation

struct PXPlayerSnapshot: Equatable {
    var state: PXPlaybackState = .idle
    var currentTime: Double = 0
    var duration: Double = 0
    var buffered: Double = 0
    var videoSize: CGSize = .zero
    var isPortraitVideo: Bool = false
    var rate: Double = 1
    var volume: Double = 1
    var isMuted: Bool = false
    var audioTracks: [PXPlaybackTrack] = []
    var subtitleTracks: [PXPlaybackTrack] = []
    var selectedAudioID: String?
    var selectedSubtitleID: String?
    var chapters: [PXPlaybackChapter] = []
    var errorMessage: String?
    var danmakuCount: Int = 0
}
