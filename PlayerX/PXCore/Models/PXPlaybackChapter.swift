import Foundation

struct PXPlaybackChapter: Identifiable, Hashable {
    var id: String
    var title: String
    var start: Double
    var end: Double

    var duration: Double { max(0, end - start) }
}
