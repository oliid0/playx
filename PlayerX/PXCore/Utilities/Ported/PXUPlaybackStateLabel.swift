import Foundation

enum PXUPlaybackStateLabel {
    static func title(_ state: PXPlaybackState) -> String {
        switch state {
        case .idle: "空闲"
        case .opening: "打开中"
        case .ready: "就绪"
        case .playing: "播放中"
        case .paused: "已暂停"
        case .buffering: "缓冲中"
        case .ended: "已结束"
        case .failed(let message): message.isEmpty ? "失败" : "失败：\(message)"
        }
    }
}
