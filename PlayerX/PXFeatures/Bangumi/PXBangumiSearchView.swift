import SwiftUI

struct PXBangumiSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @State private var query = ""
    @State private var type: PXBangumiSubjectType = .anime

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PXSearchField(text: $query, prompt: "搜索 Bangumi 条目") {
                        Task { await coordinator.search(query, type: type) }
                    }
                    HStack(spacing: 7) {
                        ForEach(PXBangumiSubjectType.allCases) { subjectType in
                            Button {
                                type = subjectType
                                Task { await coordinator.search(query, type: type) }
                            } label: {
                                PXChip(title: subjectType.title, selected: type == subjectType)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if coordinator.isLoading {
                        PXLoadingCard()
                    } else if coordinator.searchResults.isEmpty {
                        PXEmptyState(title: "搜索 Bangumi", message: "输入动画、书籍或游戏名。", symbol: "magnifyingglass")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 106), spacing: 14)], spacing: 18) {
                            ForEach(coordinator.searchResults) { subject in
                                NavigationLink {
                                    PXBangumiDetailView(subjectID: subject.id, initial: subject)
                                } label: {
                                    PXBangumiPosterCard(subject: subject)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("Bangumi 搜索")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
