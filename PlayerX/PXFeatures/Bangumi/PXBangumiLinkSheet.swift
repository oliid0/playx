import SwiftUI

struct PXBangumiLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @State private var query: String
    @State private var didSearch = false

    init(title: String) {
        _query = State(initialValue: title)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PXSearchField(text: $query, prompt: "搜索 Bangumi") {
                        Task { await search() }
                    }
                    if coordinator.isLoading {
                        PXLoadingCard()
                    } else if coordinator.searchResults.isEmpty {
                        PXEmptyState(title: "没有匹配条目", message: "可以修改关键词，或直接到 Bangumi 分区搜索。", symbol: "calendar.badge.exclamationmark")
                    } else {
                        ForEach(coordinator.searchResults) { subject in
                            NavigationLink {
                                PXBangumiDetailView(subjectID: subject.id, initial: subject)
                            } label: {
                                HStack(spacing: 11) {
                                    PXRemoteImage(url: subject.imageURL, maxPixel: 240)
                                        .frame(width: 56, height: 84).clipShape(RoundedRectangle(cornerRadius: 7))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(subject.displayTitle).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                                        Text(subject.name).font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary).lineLimit(1)
                                        HStack(spacing: 5) {
                                            if let score = subject.scoreText { PXRatingBadge(rating: Double(score)) }
                                            if let eps = subject.episodesText { PXTag(text: eps) }
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("在 Bangumi 追番")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .task {
                guard !didSearch else { return }
                didSearch = true
                await search()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func search() async {
        await coordinator.search(query, type: .anime)
    }
}
