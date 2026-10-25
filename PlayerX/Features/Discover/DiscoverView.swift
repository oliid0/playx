import SwiftUI

/// 站源目录。设计参考 OcPlayer 的 Library：顶部有站源身份卡，下面是分类 chips +
/// 自适应海报墙。旧版只有一排纯文字分类 + 大块灰卡片，层级和可读性都不够。
struct DiscoverView: View {
    @StateObject private var model: DiscoverModel

    private let columns = [
        GridItem(.adaptive(minimum: 102), spacing: 12, alignment: .top)
    ]

    init(provider: ContentProvider) {
        _model = StateObject(wrappedValue: DiscoverModel(provider: provider))
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                if model.categories.count > 1 {
                    categoryBar
                }
                content
            }
        }
        .navigationTitle(model.provider.displayName)
        .appInlineNavigationTitle()
        .appTransparentNavigationChrome()
        .searchable(text: $model.searchQuery, prompt: "搜索\(model.provider.displayName)")
        .onSubmit(of: .search) { Task { await model.submitSearch() } }
        .toolbar {
            ToolbarItem(placement: .appTrailing) {
                Button {
                    Task { await model.reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(model.isLoadingPage)
                .accessibilityLabel("刷新目录")
            }
        }
        .task {
            await model.loadCategoriesIfNeeded()
            if model.items.isEmpty {
                await model.reload()
            }
        }
    }

    // MARK: - 分类

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.categories) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, AppTheme.contentPadding)
            .padding(.vertical, 10)
        }
    }

    private func categoryChip(_ category: SourceCategory) -> some View {
        let selected = category.id == model.selectedCategoryId
        return Button {
            Task { await model.selectCategory(category.id) }
        } label: {
            Text(category.name)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundStyle(selected ? AppTheme.onBrand : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background {
                    if selected {
                        Capsule().fill(AppTheme.brandGradient)
                    } else {
                        Capsule().fill(AppTheme.surfaceMuted)
                    }
                }
                .overlay {
                    Capsule().strokeBorder(selected ? Color.clear : AppTheme.stroke, lineWidth: 0.7)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - 内容

    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 18) {
                sourceHeader

                if let message = model.errorMessage, !model.items.isEmpty {
                    inlineNotice(text: message, systemImage: "exclamationmark.triangle.fill", tint: AppTheme.warning)
                }
                if let warning = model.warning, !warning.isEmpty {
                    inlineNotice(text: warning, systemImage: "info.circle.fill", tint: AppTheme.textSecondary)
                }

                if model.isInitialLoading {
                    loadingGrid
                } else if model.items.isEmpty {
                    emptyState
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        Text(model.selectedCategoryName)
                            .font(.appSection(17))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(model.items.count) 部")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.contentPadding)

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(model.items) { drama in
                            NavigationLink {
                                DetailView(provider: model.provider, drama: drama)
                            } label: {
                                DramaPosterCard(drama: drama)
                            }
                            .buttonStyle(AppPressStyle())
                            .task { await model.loadMoreIfNeeded(near: drama) }
                        }
                    }
                    .padding(.horizontal, AppTheme.contentPadding)

                    footer
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 26)
            .frame(maxWidth: 1_320, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await model.reload() }
    }

    private var sourceHeader: some View {
        let style = SourceVisualStyle.style(for: model.provider.sourceId)
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(style.gradient)
                Image(systemName: style.symbol)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)
            .shadow(color: .black.opacity(0.28), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.provider.displayName)
                    .font(.appTitle(21))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(style.tagline)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
            Text(model.searchQuery.isEmpty ? "目录" : "搜索")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 9)
                .frame(height: 22)
                .background(Capsule().fill(AppTheme.surface))
                .overlay(Capsule().strokeBorder(AppTheme.stroke, lineWidth: 0.7))
        }
        .padding(14)
        .solidCard()
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(0..<9, id: \.self) { _ in
                SkeletonPosterCard()
            }
        }
        .padding(.horizontal, AppTheme.contentPadding)
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "square.stack.3d.up.slash",
            title: model.errorMessage == nil ? "这个分类还没有内容" : "目录加载失败",
            message: model.errorMessage ?? "换个分类，或者下拉刷新再试一次。",
            actionTitle: model.errorMessage == nil ? nil : "重试",
            action: model.errorMessage == nil ? nil : { Task { await model.reload() } }
        )
    }

    @ViewBuilder
    private var footer: some View {
        if model.isLoadingPage {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("正在加载更多")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        } else if !model.hasMore {
            Text("已经到底了 · 共 \(model.items.count) 部")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        } else if model.errorMessage == nil {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    if let last = model.items.last {
                        Task { await model.loadMoreIfNeeded(near: last) }
                    }
                }
        }
    }

    private func inlineNotice(text: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(AppTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.stroke, lineWidth: 0.7)
        }
        .padding(.horizontal, AppTheme.contentPadding)
    }
}
