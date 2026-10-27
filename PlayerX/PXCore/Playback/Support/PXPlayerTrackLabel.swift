import Foundation

enum PXPlayerTrackLabel {
    static func audio(_ track: PXPlaybackTrack) -> String {
        let detail = track.detail.map { " · \($0)" } ?? ""
        return "\(track.title)\(detail)"
    }

    static func subtitle(_ track: PXPlaybackTrack) -> String {
        track.title
    }
}
