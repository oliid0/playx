import Foundation

struct PXPlaybackRequest: Identifiable {
    let id = UUID()
    var drama: Drama
    var chapters: [Chapter]
    var provider: ContentProvider
    var chapter: Chapter
    var plan: PlaybackPlan
    var startIndex: Int
    var startPosition: Double
    var metadata: PXMediaMetadata?
    var preferredEngine: PXPlayerEngineKind?
    var preferredQuality: Int?
}
