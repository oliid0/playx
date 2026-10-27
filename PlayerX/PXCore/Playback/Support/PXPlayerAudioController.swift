import Foundation

struct PXPlayerAudioController {
    var tracks: [PXPlaybackTrack]
    var selectedID: String?

    var selected: PXPlaybackTrack? { tracks.first { $0.id == selectedID } }
    var summary: String { selected?.title ?? "默认音轨" }
}
