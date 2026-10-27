import Foundation

struct PXPlaybackSubtitleStyle: Codable, Equatable {
    var scale: Double = 1
    var opacity: Double = 1
    var verticalOffset: Double = 0

    static let `default` = PXPlaybackSubtitleStyle()
}
