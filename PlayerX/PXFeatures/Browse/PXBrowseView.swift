import SwiftUI

struct PXBrowseView: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model: PXBrowseViewModel
    @State private var showFilter = false

    init(section: PXCatalogSection, initialSource: String? = nil) {
        _model = StateObject(wrappedValue: PXBrowseViewModel(section: section, initialSource: initialSource))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    header(width: proxy.size.width)
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showFilter = true } label: {
                    Image(systemName: model.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("筛选")
            }
        }
        .task { await model.load() }
        .sheet(isPresented: $showFilter) {
            PXFilterSheet(filter: model.filter) { filter in
                Task { await model.apply(filter) }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(PXFont.display(width > 800 ? 36 : 30))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text(model.subtitle)
                        .font(PXFont.caption(12))
                        .foregroundStyle(PXTheme.textTertiary)
                }
                Spacer()
            }
            if model.filter.isActive {
                HStack(spacing: 7) {
                    if let kind = model.filter.kind { PXTag(text: kind.title, tint: PXTheme.accent) }
                    if let source = model.filter.sourceID,
                       let descriptor = SourceRegistry.descriptor(for: source) {
                        PXTag(text: descriptor.displayName, tint: PXTheme.sky)
                    }
                    if let genre = model.filter.genre { PXTag(text: genre, tint: PXTheme.mint) }
                    if let year = model.filter.year { PXTag(text: String(year), tint: PXTheme.rose) }
                    Button("清除") {
                        Task { await model.apply(PXCatalogFilter(kind: model.section.mediaKind)) }
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(PXTheme.textTertiary)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, PXTheme.padding(for: width))
        .padding(.top, 10)
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
            ForEach(model.items) { entry in
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
