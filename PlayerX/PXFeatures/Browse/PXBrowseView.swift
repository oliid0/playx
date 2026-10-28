import SwiftUI

struct PXBrowseView: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model: PXBrowseViewModel
    @State private var searchText = ""

    init(section: PXCatalogSection, initialSource: String? = nil) {
        _model = StateObject(wrappedValue: PXBrowseViewModel(section: section, initialSource: initialSource))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if !model.categories.isEmpty {
                        categoryBar(width: proxy.size.width)
                    }
                    if model.isLoading {
                        loadingGrid(width: proxy.size.width)
                    } else if model.items.isEmpty {
                        PXEmptyState(
                            title: model.errorMessage == nil ? "这里还没有内容" : "目录加载失败",
                            message: model.errorMessage ?? "换一个分类或筛选条件再试试。",
                            symbol: "square.stack.3d.up.slash",
                            actionTitle: "重试",
                            action: { Task { await model.reload() } }
                        )
                    } else if displayedItems.isEmpty {
                        PXEmptyState(title: "没有匹配内容", message: "换个关键词或分类再试试。", symbol: "magnifyingglass")
                    } else {
                        grid(width: proxy.size.width)
                        footer
                    }
                }
                .padding(.bottom, 32)
            }
            .refreshable { await model.reload() }
        }
        .background(PXPageBackground())
        .navigationTitle(model.title)
        .pxInlineNavigationTitle()
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索本库")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(PXCatalogSort.allCases) { sort in
                        Button {
                            var filter = model.filter
                            filter.sort = sort
                            Task { await model.apply(filter) }
                        } label: {
                            Label(sort.title, systemImage: sort.symbol)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("排序")
            }
        }
        .pxBackCommand()
        .onAppear { app.enterPage(title: model.title) }
        .onDisappear { app.leavePage() }
        .task { await model.load() }
    }


    private func categoryBar(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                Button {
                    Task { await model.selectCategory("") }
                } label: {
                    PXChip(title: "全部", selected: model.selectedCategory.isEmpty)
                }
                .buttonStyle(.plain)
                ForEach(model.categories) { category in
                    Button {
                        Task { await model.selectCategory(category.id) }
                    } label: {
                        PXChip(title: category.name, selected: model.selectedCategory == category.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.padding(for: width))
        }
    }

    private func grid(width: CGFloat) -> some View {
        LazyVGrid(columns: PXAdaptiveColumns.posters(width: width), spacing: 18) {
            ForEach(displayedItems) { entry in
                NavigationLink {
                    PXDetailView(entry: entry)
                } label: {
                    PXPosterCard(entry: entry)
                }
                .buttonStyle(.plain)
                .task { await model.loadMoreIfNeeded(current: entry) }
            }
        }
        .padding(.horizontal, PXTheme.padding(for: width))
    }

    private func loadingGrid(width: CGFloat) -> some View {
        LazyVGrid(columns: PXAdaptiveColumns.posters(width: width), spacing: 18) {
            ForEach(0..<12, id: \.self) { _ in
                PXSkeletonPoster(width: 140)
            }
        }
        .padding(.horizontal, PXTheme.padding(for: width))
    }

    private var displayedItems: [PXCatalogEntry] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return model.items }
        return model.items.filter {
            $0.drama.title.localizedCaseInsensitiveContains(text)
                || ($0.drama.description ?? "").localizedCaseInsensitiveContains(text)
        }
    }

    private var footer: some View {
        Group {
            if model.isLoadingMore {
                PXLoadingCard()
            } else if !model.hasMore {
                Text("已经到底了 · 共 \(model.items.count) 部")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
    }
}
