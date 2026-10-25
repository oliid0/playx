import SwiftUI
import Foundation

/// 全站搜索。不用系统 `.searchable`：这里需要「搜索范围 chips + 取消 + 结果统计」
/// 一整套顶栏，而且搜索本身就是这个 Sheet 的主内容，系统搜索栏反而占两层。
struct GlobalSearchView: View {
    @StateObject private var model = GlobalSearchModel()
    @ObservedObject private var lock = SourceLockStore.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12, alignment: .top)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    searchBar
                    scopeBar
                    content
                }
            }
            .navigationTitle("搜索")
            .appHideNavigationBar()
            .task(id: "\(model.query)|\(model.scopeSourceId ?? "all")|\(lock.isUnlockedThisLaunch)") {
                guard !model.trimmedQuery.isEmpty else {
                    model.clear()
                    return
                }
                do {
                    try await Task.sleep(nanoseconds: 450_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                await model.search()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    searchFocused = true
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 620)
        #endif
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)

                TextField("搜索剧名、演员、关键词", text: $model.query)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .appSearchFieldBehavior()
                    .onSubmit {
                        Task { await model.search() }
                    }

                if !model.query.isEmpty {
                    Button {
                        model.query = ""
                        searchFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("清空搜索")
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(AppTheme.stroke, lineWidth: 0.8)
            }

            Button("取消") { dismiss() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, AppTheme.contentPadding)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var scopeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                scopeChip(title: "全部", sourceId: nil)
                ForEach(model.availableSources) { descriptor in
                    scopeChip(title: descriptor.displayName, sourceId: descriptor.id)
                }
            }
            .padding(.horizontal, AppTheme.contentPadding)
        }
        .padding(.bottom, 10)
    }

    private func scopeChip(title: String, sourceId: String?) -> some View {
        let selected = model.scopeSourceId == sourceId
        return Button {
            model.scopeSourceId = sourceId
        } label: {
            Text(title)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundStyle(selected ? AppTheme.onBrand : AppTheme.textSecondary)
                .padding(.horizontal, 13)
                .frame(height: 30)
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
    }

    @ViewBuilder
    private var content: some View {
        if model.trimmedQuery.isEmpty {
            EmptyStateView(
                systemImage: "sparkle.magnifyingglass",
                title: "搜点什么",
                message: "输入剧名或关键词，会同时搜索所有已解锁的站源。"
            )
            .frame(maxHeight: .infinity)
        } else if model.isSearching && model.results.isEmpty {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonPosterCard()
                    }
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.top, 14)
            }
        } else if let error = model.errorMessage, model.results.isEmpty {
            EmptyStateView(
                systemImage: "wifi.exclamationmark",
                title: "搜索失败",
                message: error,
                actionTitle: "重试",
                action: { Task { await model.search() } }
            )
            .frame(maxHeight: .infinity)
        } else if model.hasSearched && model.results.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "没有找到「\(model.trimmedQuery)」",
                message: "换个关键词，或者切换上面的站源范围再试一次。"
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text("找到 \(model.results.count) 部")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                        if model.isSearching {
                            ProgressView()
                                .controlSize(.small)
                                .tint(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.contentPadding)

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(model.results) { drama in
                            if let descriptor = SourceRegistry.descriptor(for: drama.source) {
                                NavigationLink {
                                    DetailView(provider: descriptor.provider, drama: drama)
                                } label: {
                                    DramaPosterCard(drama: drama, showsSource: true)
                                }
                                .buttonStyle(AppPressStyle())
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.contentPadding)
                    .padding(.bottom, 24)
                }
                .padding(.top, 6)
            }
        }
    }
}
