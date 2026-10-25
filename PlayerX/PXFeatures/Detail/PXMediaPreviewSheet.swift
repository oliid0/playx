import SwiftUI

/// TMDB-only 推荐内容的轻量详情。没有站源播放地址，只展示资料；用户可返回
/// 站源搜索同名内容。
struct PXMediaPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let recommendation: PXMediaRecommendation
    @State private var metadata: PXMediaMetadata?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PXDetailBackdrop(
                        url: metadata?.backdropURL ?? PXImageURL.backdrop(recommendation.backdropPath),
                        logoURL: metadata?.logoURL,
                        title: metadata?.title ?? recommendation.title,
                        height: 340
                    )
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            PXRemoteImage(url: metadata?.posterURL ?? recommendation.posterURL, maxPixel: 500)
                                .frame(width: 88, height: 132)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(metadata?.title ?? recommendation.title)
                                    .font(PXFont.title(22))
                                    .foregroundStyle(PXTheme.textPrimary)
                                PXMetadataLine(parts: [
                                    metadata?.yearText ?? recommendation.yearText,
                                    metadata?.genreText,
                                ].compactMap { $0 })
                                PXRatingBadge(rating: metadata?.rating ?? recommendation.rating)
                            }
                            Spacer()
                        }
                        Text(metadata?.overview ?? recommendation.overview ?? "暂无简介")
                            .font(.system(size: 13))
                            .foregroundStyle(PXTheme.textSecondary)
                            .lineSpacing(4)
                        if let metadata {
                            PXInfoRow(title: "TMDB", value: "\(metadata.tmdbID)")
                            PXInfoRow(title: "时长", value: metadata.runtimeText)
                            PXInfoRow(title: "分级", value: metadata.contentRating)
                        }
                    }
                    .padding(.horizontal, PXTheme.contentPadding)
                }
                .padding(.bottom, 24)
            }
            .background(PXPageBackground())
            .navigationTitle("相关内容")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                metadata = await PXMetadataCoordinator.shared.detail(
                    tmdbID: recommendation.tmdbID, kind: recommendation.mediaType
                )
                isLoading = false
            }
            .overlay {
                if isLoading { PXLoadingCard() }
            }
        }
        .preferredColorScheme(.dark)
    }
}
