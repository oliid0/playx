import SwiftUI

struct PXHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @StateObject private var model = PXHomeViewModel()
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var follow = FollowStore.shared
    @State private var heroIndex = 0
    @State private var showSourcePicker = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    PXHomeHeader(onSearch: { app.searchPresented = true })
                        .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                        .padding(.top, PXPlatform.isMac ? 18 : 8)
                    categoryStrip
                        .padding(.top, 18)
                    heroSection(width: proxy.size.width)
                        .padding(.top, 16)
                    continueSection(width: proxy.size.width)
                    railsSection(width: proxy.size.width)
                    sourceRail(width: proxy.size.width)
                    footer
                }
                .padding(.bottom, 36)
            }
            .refreshable { await model.reload() }
            .background {
                PXBackdropAmbience(url: heroBackdrop, intensity: 0.9)
            }
        }
        .background(PXPageBackground())
        .navigationTitle("首页")
        .pxHiddenNavigationBar()
        .task { await model.loadIfNeeded() }
        .onChange(of: model.heroItems.count) { count in
            if heroIndex >= count { heroIndex = 0 }
        }
        .sheet(isPresented: $showSourcePicker) {
            PXSourcePickerView()
                .presentationDetents([.medium, .large])
        }
    }

    private var heroBackdrop: URL? {
        if model.heroItems.indices.contains(heroIndex) {
            return model.heroItems[heroIndex].backdropURL
        }
        return model.heroItems.first?.backdropURL
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                NavigationLink {
                    PXBrowseView(section: .library)
                } label: {
                    PXChip(title: "全部", symbol: "square.grid.2x2", selected: true)
                }
                .buttonStyle(.plain)
                ForEach(PXCatalogSection.contentSections.filter { $0 != .home }) { section in
                    NavigationLink {
                        PXBrowseView(section: section)
                    } label: {
                        PXChip(title: section.title, symbol: section.symbol)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.contentPadding)
        }
    }

    @ViewBuilder
    private func heroSection(width: CGFloat) -> some View {
        if model.heroItems.isEmpty {
            if model.isLoading {
                RoundedRectangle(cornerRadius: 26)
                    .fill(PXTheme.surfaceMuted)
                    .frame(height: PXTheme.heroHeight)
                    .overlay(PXShimmer())
                    .padding(.horizontal, PXTheme.contentPadding)
            } else {
                PXEmptyState(
                    title: "今天还没有推荐",
                    message: model.errorMessage ?? "下拉刷新，或到片库直接浏览站源。",
                    symbol: "sparkles.tv",
                    actionTitle: "打开片库",
                    action: { app.selectedSection = .library }
                )
            }
        } else {
            VStack(spacing: 12) {
                #if os(iOS)
                TabView(selection: $heroIndex) {
                    ForEach(Array(model.heroItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            PXDetailView(entry: item.entry)
                        } label: {
                            PXHeroCard(item: item, height: PXTheme.heroHeight)
                        }
                        .buttonStyle(PXPressStyle(scale: 0.995))
                        .padding(.horizontal, PXTheme.padding(for: width))
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: PXTheme.heroHeight)
                #else
                HStack(spacing: 8) {
                    heroStep(-1)
                    NavigationLink {
                        PXDetailView(entry: model.heroItems[min(heroIndex, model.heroItems.count - 1)].entry)
                    } label: {
                        PXHeroCard(item: model.heroItems[min(heroIndex, model.heroItems.count - 1)], height: PXTheme.heroHeight)
                    }
                    .buttonStyle(PXPressStyle(scale: 0.995))
                    heroStep(1)
                }
                .padding(.horizontal, PXTheme.widePadding)
                #endif

                HStack(spacing: 6) {
                    ForEach(model.heroItems.indices, id: \.self) { index in
                        Button {
                            withAnimation(PXTheme.heroMotion) { heroIndex = index }
                        } label: {
                            Capsule()
                                .fill(index == heroIndex ? PXTheme.accent : Color.white.opacity(0.22))
                                .frame(width: index == heroIndex ? 22 : 6, height: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    #if os(macOS)
    private func heroStep(_ delta: Int) -> some View {
        Button {
            guard !model.heroItems.isEmpty else { return }
            let count = model.heroItems.count
            withAnimation(PXTheme.heroMotion) {
                heroIndex = (heroIndex + delta + count) % count
            }
        } label: {
            Image(systemName: delta > 0 ? "chevron.right" : "chevron.left")
        }
        .buttonStyle(PXIconButtonStyle(size: 38))
    }
    #endif

    @ViewBuilder
    private func continueSection(width: CGFloat) -> some View {
        let entries = history.entries.sorted { $0.updatedAt > $1.updatedAt }.prefix(10)
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                PXSectionHeader(
                    title: "继续观看",
                    subtitle: "从上次看到的位置接着看",
                    symbol: "clock.arrow.circlepath"
                )
                .padding(.horizontal, PXTheme.padding(for: width))
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(Array(entries)) { entry in
                            if let descriptor = SourceRegistry.descriptor(for: entry.drama.source) {
                                NavigationLink {
                                    PXDetailView(entry: PXCatalogEntry(
                                        drama: entry.drama,
                                        section: .library,
                                        providerID: descriptor.id
                                    ), resume: entry)
                                } label: {
                                    PXContinueCard(entry: entry, width: width > 800 ? 300 : 260)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, PXTheme.padding(for: width))
                }
            }
            .padding(.top, 26)
        }
    }

    @ViewBuilder
    private func railsSection(width: CGFloat) -> some View {
        ForEach(model.rails) { rail in
            VStack(alignment: .leading, spacing: 11) {
                PXSectionHeader(
                    title: rail.title,
                    subtitle: rail.subtitle,
                    symbol: rail.symbol,
                    actionTitle: rail.seeAllSection == nil ? nil : "查看全部",
                    action: rail.seeAllSection.map { section in
                        { app.selectedSection = section }
                    }
                )
                .padding(.horizontal, PXTheme.padding(for: width))

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 13) {
                        ForEach(rail.entries) { entry in
                            NavigationLink {
                                PXDetailView(entry: entry)
                            } label: {
                                if rail.style == .poster {
                                    PXPosterCard(entry: entry, width: width > 800 ? 158 : 132)
                                } else {
                                    PXLandscapeCard(entry: entry, width: width > 800 ? 300 : 246)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, PXTheme.padding(for: width))
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 28)
        }
    }

    private func sourceRail(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            PXSectionHeader(
                title: "站源",
                subtitle: "\(model.sources.count) 个可用内容库",
                symbol: "server.rack",
                actionTitle: "管理",
                action: { showSourcePicker = true }
            )
            .padding(.horizontal, PXTheme.padding(for: width))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.sources) { source in
                        NavigationLink {
                            PXSourceBrowseView(descriptor: source)
                        } label: {
                            PXSourceCard(descriptor: source, width: width > 800 ? 170 : 146)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, PXTheme.padding(for: width))
            }
        }
        .padding(.top, 28)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PlayerX · 多内核原生播放器")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PXTheme.textTertiary)
            Text("内容来自公开站源，元数据由 TMDB 提供；弹幕由弹弹play 提供。")
                .font(.system(size: 9))
                .foregroundStyle(PXTheme.textTertiary.opacity(0.7))
        }
        .padding(.horizontal, PXTheme.contentPadding)
        .padding(.top, 32)
    }
}
