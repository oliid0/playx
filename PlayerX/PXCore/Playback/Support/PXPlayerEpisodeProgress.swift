import Foundation

struct PXPlayerEpisodeProgress {
    var index: Int
    var total: Int
    var current: Double
    var duration: Double

    var fraction: Double { duration > 0 ? min(max(current / duration, 0), 1) : 0 }
    var text: String { "第 \(index + 1) / \(total) 集" }
}
