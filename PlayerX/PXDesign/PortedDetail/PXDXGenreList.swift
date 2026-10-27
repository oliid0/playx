import SwiftUI

struct PXDXGenreList: View {
    let genres: [String]
    var body: some View {
        PXUITagWrap(tags: genres)
    }
}
