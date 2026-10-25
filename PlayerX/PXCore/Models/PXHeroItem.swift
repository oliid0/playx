import Foundation

struct PXHeroItem: Identifiable {
    var entry: PXCatalogEntry
    var title: String
    var subtitle: String
    var overview: String?
    var backdropURL: URL?
    var logoURL: URL?
    var rating: Double?
    var genres: [String]

    var id: String { entry.id }

    init(entry: PXCatalogEntry, metadata: PXMediaMetadata? = nil) {
        self.entry = entry
        self.title = metadata?.title ?? entry.drama.title
        self.subtitle = metadata?.yearText ?? entry.drama.pxDisplaySubtitle
        self.overview = metadata?.overview ?? entry.drama.description
        self.backdropURL = metadata?.backdropURL
        self.logoURL = metadata?.logoURL
        self.rating = metadata?.rating
        self.genres = metadata?.genres ?? entry.drama.pxGenres
    }
}
