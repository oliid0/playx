import SwiftUI

/// 从 Bangumi / TMDB 的条目跳回站源搜索，用标题直接找可播放版本。
struct PXSourceSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let query: String
    @State private var results: [PXCatalogEntry] = []
    @State private var isLoading = true
    @State private var searchText: String

    init(query: String) {
        self.query = query
        _searchText = State(initialValue: query)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    PXSearchField(text: $searchText, prompt: "在站源中搜索") {
                        Task { await search() }
                    }
                    if isLoading {
                        PXLoadingCard()
                    } else if results.isEmpty {
                        PXEmptyState(title: "站源没有找到", message: "可以换个标题，或到片库浏览。", symbol: "magnifyingglass")
                    } else {
                        ForEach(results) { entry in
                            NavigationLink {
                                PXDetailView(entry: entry)
                            } label: {
                                HStack(spacing: 11) {
                                    PXRemoteImage(url: URL(string: entry.drama.cover ?? ""), maxPixel: 240)
                                        .frame(width: 54, height: 81).clipShape(RoundedRectangle(cornerRadius: 7))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(entry.drama.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                                        Text(entry.drama.pxDisplaySubtitle).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                                        HStack(spacing: 5) {
                                            PXTag(text: entry.providerID, tint: PXTheme.sky)
                                            if let count = entry.drama.pxEpisodeCount { PXTag(text: "\(count) 集") }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("找可播放版本")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .task { await search() }
        }
        .preferredColorScheme(.dark)
    }

    private func search() async {
        isLoading = true
        results = await PXCatalogService.shared.search(query: searchText, scope: .sources)
        isLoading = false
    }
}
