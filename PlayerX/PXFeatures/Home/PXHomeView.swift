import SwiftUI

/// 首页严格按 OcPlayer 的栏目顺序组织：继续观看 / 接下来看 / 最近添加 / 媒体库。
/// 不再放 Hero 轮播、类型 Chips、站源卡片和“片库”一级 Tab——这些入口在
/// OcPlayer 里都不存在，也是上一版界面的杂乱来源。
struct PXHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model = PXHomeViewModel()
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var follow = FollowStore.shared
    @ObservedObject private var sourceStore = PXSourceConfigurationStore.shared
    @AppStorage(PXHomeSectionPreference.storageKey) private var hiddenSectionsRaw = ""

    private var hiddenSections: Set<PXHomeSection> {
        PXHomeSectionPreference.hidden(from: hiddenSectionsRaw)
    }

    private func shows(_ section: PXHomeSection) -> Bool {
        !hiddenSections.contains(section)
    }

    private var continueItems: [HistoryEntry] {
        Array(history.entries.sorted { $0.updatedAt > $1.updatedAt }.prefix(12))
    }

    private var nextUp: [PXCatalogEntry] {
        follow.entries
            .filter { $0.status == .watching || $0.status == .planned }
            .compactMap { entry in
                guard let descriptor = SourceRegistry.descriptor(for: entry.drama.source) else { return nil }
                return PXCatalogEntry(drama: entry.drama, section: .library, providerID: descriptor.id)
            }
            .prefix(12)
            .map { $0 }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if shows(.continueWatching), !continueItems.isEmpty {
                        rail(title: "继续观看", subtitle: nil) {
                            ForEach(continueItems) { entry in
                                if let descriptor = SourceRegistry.descriptor(for: entry.drama.source) {
                                    NavigationLink {
                                        PXDetailView(
                                            entry: PXCatalogEntry(drama: entry.drama, section: .library, providerID: descriptor.id),
                                            resume: entry
                                        )
                                    } label: {
                                        PXContinueCard(entry: entry, width: proxy.size.width > 1_200 ? 390 : (proxy.size.width > 900 ? 320 : 260))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if shows(.nextUp), !nextUp.isEmpty {
                        rail(title: "接下来看", subtitle: nil) {
                            ForEach(nextUp) { entry in
                                NavigationLink {
                                    PXDetailView(entry: entry)
                                } label: {
                                    PXLandscapeCard(entry: entry, width: proxy.size.width > 900 ? 300 : 258)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if model.isLoading && model.latest.isEmpty {
                        skeletonRail(width: proxy.size.width)
                    } else if shows(.latest), !model.latest.isEmpty {
                        rail(title: "最近添加", subtitle: nil) {
                            ForEach(model.latest) { entry in
                                NavigationLink {
                                    PXDetailView(entry: entry)
                                } label: {
                                    PXLandscapeCard(entry: entry, width: proxy.size.width > 900 ? 300 : 258)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if shows(.libraries) {
                        rail(title: "媒体库", subtitle: nil) {
                            ForEach(model.libraries) { descriptor in
                                NavigationLink {
                                    PXSourceBrowseView(descriptor: descriptor)
                                } label: {
                                    PXLibraryCard(
                                        descriptor: descriptor,
                                        covers: model.libraryCovers[descriptor.id] ?? [],
                                        width: proxy.size.width > 900 ? 300 : 258
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            Button {
                                app.select(.profile)
                            } label: {
                                addLibraryCard
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !model.isLoading, continueItems.isEmpty, nextUp.isEmpty, model.latest.isEmpty, model.libraries.isEmpty {
                        ForEach(model.libraries) { descriptor in
                            NavigationLink {
                                PXSourceBrowseView(descriptor: descriptor)
                            } label: {
                                PXLibraryCard(
                                    descriptor: descriptor,
                                    covers: model.libraryCovers[descriptor.id] ?? [],
                                    width: proxy.size.width > 900 ? 300 : 258
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            app.select(.profile)
                        } label: {
                            addLibraryCard
                        }
                        .buttonStyle(.plain)
                    }

                    if !model.isLoading, continueItems.isEmpty, nextUp.isEmpty, model.latest.isEmpty, model.libraries.isEmpty {
                        PXEmptyState(
                            title: "还没有媒体库",
                            message: model.errorMessage ?? "到设置中添加站源、Jellyfin、Emby、WebDAV 或 MacCMS。",
                            symbol: "rectangle.stack.badge.plus",
                            actionTitle: "去设置",
                            action: { app.select(.profile) }
                        )
                        .padding(.horizontal, PXTheme.contentPadding)
                    }

                    if let error = model.errorMessage, !model.isLoading, model.latest.isEmpty {
                        PXErrorBanner(message: error) {
                            Task { await model.reload() }
                        }
                        .padding(.horizontal, PXTheme.contentPadding)
                        .padding(.top, 12)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 36)
            }
            .refreshable { await model.reload() }
        }
        .background {
            if let seed = model.latest.first?.drama ?? continueItems.first?.drama {
                PXAmbientCover(drama: seed)
            } else {
                PXPageBackground()
            }
        }
        .navigationTitle("")
        .pxInlineNavigationTitle()
        .pxTransparentNavigation()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if model.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Button { Task { await model.reload() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("刷新首页")
                }
            }
        }
        .task { await model.loadIfNeeded() }
        .onChange(of: sourceStore.configurations.count) { _ in
            Task { await model.reload() }
        }
    }

    private var librariesSubtitle: String {
        let count = model.libraries.count
        let external = model.libraries.filter(\.isExternal).count
        if count == 0 { return "添加站源或外部媒体源" }
        if external == 0 { return "\(count) 个内置站源" }
        return "\(count) 个媒体库 · \(external) 个外部源"
    }

    private func rail<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(PXTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            .padding(.horizontal, PXTheme.contentPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    content()
                }
                .padding(.horizontal, PXTheme.contentPadding)
                .padding(.vertical, 3)
            }
        }
        .padding(.top, 24)
    }

    private func skeletonRail(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            RoundedRectangle(cornerRadius: 4).fill(PXTheme.surface).frame(width: 110, height: 20)
                .padding(.horizontal, PXTheme.contentPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(PXTheme.surfaceMuted)
                            .frame(width: 260, height: 146)
                            .overlay(PXShimmer())
                    }
                }
                .padding(.horizontal, PXTheme.contentPadding)
            }
        }
        .padding(.top, 24)
    }

    private var addLibraryCard: some View {
        VStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(PXTheme.surfaceMuted)
                VStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(PXTheme.accent)
                    Text("添加媒体库")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PXTheme.textSecondary)
                }
            }
            .frame(width: 258, height: 145)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PXTheme.stroke, lineWidth: 0.7))
            Text("站源 / Jellyfin / WebDAV / MacCMS")
                .font(.system(size: 9))
                .foregroundStyle(PXTheme.textTertiary)
                .frame(width: 258, alignment: .leading)
        }
        .frame(width: 258, alignment: .leading)
    }
}
