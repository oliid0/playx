import SwiftUI

struct PXDXRecommendationRail: View {
    let items: [PXMediaRecommendation]
    let onSelect: (PXMediaRecommendation) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    Button { onSelect(item) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            PXRemoteImage(url: item.posterURL, maxPixel: 300)
                                .frame(width: 104, height: 156)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                            Text(item.title).font(PXFont.caption(10)).lineLimit(1).frame(width: 104, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
