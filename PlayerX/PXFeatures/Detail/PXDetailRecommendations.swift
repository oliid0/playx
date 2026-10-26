import SwiftUI

struct PXDetailRecommendations: View {
    @ObservedObject var model: PXDetailViewModel
    var onSelect: (PXMediaRecommendation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PXSectionHeader(title: "相关推荐", subtitle: nil, symbol: "sparkles")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(model.recommendations) { item in
                        Button { onSelect(item) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                PXRemoteImage(url: item.posterURL, maxPixel: 400)
                                    .frame(width: 112, height: 168)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(item.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(PXTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 112, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }
}
