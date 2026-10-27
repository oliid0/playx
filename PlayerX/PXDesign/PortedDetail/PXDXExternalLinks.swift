import SwiftUI

struct PXDXExternalLinks: View {
    let metadata: PXMediaMetadata
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let homepage = metadata.homepage, let url = URL(string: homepage) {
                Link(destination: url) { PXUIIconLabel(icon: "safari", text: "官方网站") }
            }
            if let imdb = metadata.imdbID, let url = URL(string: "https://www.imdb.com/title/\(imdb)/") {
                Link(destination: url) { PXUIIconLabel(icon: "film", text: "IMDb") }
            }
            Link(destination: URL(string: "https://www.themoviedb.org/\(metadata.mediaType == .movie ? "movie" : "tv")/\(metadata.tmdbID)")!) {
                PXUIIconLabel(icon: "link", text: "TMDB")
            }
        }
    }
}
