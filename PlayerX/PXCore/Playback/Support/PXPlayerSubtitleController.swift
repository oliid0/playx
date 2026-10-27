import Foundation

struct PXPlayerSubtitleController {
    var tracks: [PXPlaybackTrack]
    var selectedID: String?

    var selected: PXPlaybackTrack? { tracks.first { $0.id == selectedID } }
    var isOff: Bool { selectedID == nil || selectedID?.isEmpty == true }
    var summary: String {
        if isOff { return "关闭" }
        return selected?.title ?? "未知字幕"
    }
}
