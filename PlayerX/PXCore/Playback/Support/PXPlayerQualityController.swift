import Foundation

struct PXPlayerQualityController {
    var current: Int?
    var options: [PXPlaybackQualityOption]

    var title: String { PXFormat.quality(current ?? 0) }
    var available: [PXPlaybackQualityOption] {
        options.isEmpty ? [.auto] : options
    }
}
