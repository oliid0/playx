import Foundation

struct PXUPlayerBadgeModel {
    var engine: PXPlayerEngineKind
    var quality: Int
    var isHDR: Bool = false
    var audioLabel: String?
    var subtitleLabel: String?
}
