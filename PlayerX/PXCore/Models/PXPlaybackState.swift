import Foundation

enum PXPlaybackState: Equatable {
    case idle
    case opening
    case ready
    case playing
    case paused
    case buffering
    case ended
    case failed(String)

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .opening, .buffering: true
        default: false
        }
    }

    var title: String {
        switch self {
        case .idle: "待播放"
        case .opening: "正在打开"
        case .ready: "就绪"
        case .playing: "播放中"
        case .paused: "已暂停"
        case .buffering: "缓冲中"
        case .ended: "播放结束"
        case .failed: "播放失败"
        }
    }
}
