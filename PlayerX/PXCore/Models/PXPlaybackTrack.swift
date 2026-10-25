import Foundation

struct PXPlaybackTrack: Identifiable, Hashable {
    enum Kind: Hashable {
        case audio
        case subtitle
    }

    var id: String
    var kind: Kind
    var title: String
    var detail: String?
    var isSelected: Bool
}
