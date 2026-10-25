import SwiftUI

struct PXTMDbMatchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: PXDetailViewModel
    @State private var query: String
    @State private var results: [PXTMDbSearchResult] = []
    @State private var isSearching = false

    init(model: PXDetailViewModel) {
        self.model = model
        _query = State(initialValue: model.drama.title)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PXSearchField(text: $query, prompt: "输入片名搜索 TMDB") {
                        Task { await search() }
                    }
                    if isSearching {
                        PXLoadingCard()
                    } else if results.isEmpty {
                        PXEmptyState(
                            title: "没有搜索结果",
                            message: "可以试试原始日文名、英文名，或去掉季数后缀。",
                            symbol: "magnifyingglass"
                        )
                    } else {
                        ForEach(results, id: \.id) { result in
                            Button {
                                Task {
                                    await model.manuallyMatch(result)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    PXRemoteImage(
                                        url: PXImageURL.poster(result.posterPath, width: 185),
                                        maxPixel: 300
                                    )
                                    .frame(width: 62, height: 93)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.displayTitle)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(PXTheme.textPrimary)
                                        Text(result.originalTitle ?? result.originalName ?? "")
                                            .font(.system(size: 10))
                                            .foregroundStyle(PXTheme.textTertiary)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            if let year = result.year { PXTag(text: String(year)) }
                                            if let rating = result.voteAverage, rating > 0 {
                                                PXRatingBadge(rating: rating)
                                            }
                                            PXTag(text: result.mediaType == "movie" ? "电影" : "剧集", tint: PXTheme.sky)
                                        }
                                        if let overview = result.overview, !overview.isEmpty {
                                            Text(overview)
                                                .font(.system(size: 9))
                                                .foregroundStyle(PXTheme.textTertiary)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(10)
                                .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("匹配元数据")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                if model.metadata != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("取消匹配", role: .destructive) {
                            Task { await model.clearMatch(); dismiss() }
                        }
                    }
                }
            }
            .task { await search() }
        }
        .preferredColorScheme(.dark)
    }

    private func search() async {
        isSearching = true
        results = await model.searchMetadata(query)
        isSearching = false
    }
}
