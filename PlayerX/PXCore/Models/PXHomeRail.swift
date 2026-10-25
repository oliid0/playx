import Foundation

struct PXHomeRail: Identifiable {
    enum Style: Hashable {
        case poster
        case landscape
        case ranking
        case sources
    }

    var id: String
    var title: String
    var subtitle: String?
    var symbol: String
    var style: Style
    var entries: [PXCatalogEntry]
    var seeAllSection: PXCatalogSection?
}
