import SwiftUI
import Combine
import Foundation

/// 发现首页。结构参考 OcPlayer 的「氛围首页」：顶部轻量品牌栏 → Hero 编辑推荐 →
/// 继续观看 → 站源入口 → 站源推荐栏。和旧版「一进来就是站源 List」相比，
/// 用户第一眼看到的是内容，而不是配置。
struct HomeView: View {
    @StateObject private var model = HomeModel()
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var lock = SourceLockStore.shared

    @State private var heroIndex = 0
    @State private var showingLockSheet = false
    @State private var showingSources = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    private var horizontalPadding: CGFloat { AppTheme.contentPadding }
    private var isCompact: Bool {
        #if os(iOS)
        sizeClass == .compact
        #else
        false
        #endif
    }
    private var stillWidth: CGFloat { isCompact ? AppTheme.compactStillWidth : AppTheme.stillWidth }
    private var posterWidth: CGFloat { isCompact ? AppTheme.compactPosterWidth : AppTheme.posterWidth }

    var body: some View {
        ZStack {
            homeBackground

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if isCompact {
                        header
                    }
                    continueWatchingSection
                    sourceSection
                    shelfSections
                    footer
                }
                .padding(.top, 6)
                .padding(.bottom, 28)
                .frame(maxWidth: 1_240, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await model.reload() }
        }
        .navigationTitle("首页")
        .appInlineNavigationTitle()
        .appHideNavigationBarOnCompact()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    NotificationCenter.default.post(name: .playerXOpenSearch, object: nil)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel("搜索全部站源")
            }
        }
        .task { await model.loadIfNeeded() }
        .onChange(of: model.heroItems.count) { count in
            if heroIndex >= count {
                heroIndex = 0
            }
        }
        .sheet(isPresented: $showingLockSheet) {
            SourceLockView()
        }
        .navigationDestination(isPresented: $showingSources) {
            SourcesView()
        }
    }

    // MARK: - 顶部

    private var homeBackground: some View {
        Group {
            if let drama = history.entries.first?.drama
                ?? model.heroItems.first?.drama
                ?? model.shelves.first?.items.first {
                AmbientCoverBackground(drama: drama, intensity: 0.9)
            } else {
                AppBackground()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("首页")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer(minLength: 8)

            Button {
                NotificationCenter.default.post(name: .playerXOpenSearch, object: nil)
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.stroke, lineWidth: 0.8))
            }
            .buttonStyle(AppPressStyle())
            .accessibilityLabel("搜索全部站源")
        }
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if model.heroItems.isEmpty {
            if model.isLoading {
                VStack(spacing: 12) {
                    SkeletonBlock(radius: 24)
                        .frame(height: 330)
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule().fill(AppTheme.surface).frame(width: 16, height: 4)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            } else if model.errorMessage != nil {
                featureFallback
                    .padding(.horizontal, horizontalPadding)
            } else {
                featureFallback
                    .padding(.horizontal, horizontalPadding)
            }
        } else {
            VStack(spacing: 12) {
                #if os(iOS)
                TabView(selection: $heroIndex) {
                    ForEach(Array(model.heroItems.enumerated()), id: \.element.id) { index, item in
                        heroPage(item)
                            .tag(index)
                            .padding(.horizontal, horizontalPadding)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 330)
                #else
                HStack(spacing: 8) {
                    heroStepButton(systemImage: "chevron.left") {
                        stepHero(by: -1)
                    }
                    heroPage(model.heroItems[min(heroIndex, model.heroItems.count - 1)])
                    heroStepButton(systemImage: "chevron.right") {
                        stepHero(by: 1)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .frame(height: 330)
                #endif

                HStack(spacing: 6) {
                    ForEach(model.heroItems.indices, id: \.self) { index in
                        Button {
                            withAnimation(AppTheme.hero) { heroIndex = index }
                        } label: {
                            Capsule()
                                .fill(index == heroIndex ? AppTheme.brand : Color.white.opacity(0.22))
                                .frame(width: index == heroIndex ? 18 : 6, height: 5)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("推荐第 \(index + 1) 个")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heroPage(_ item: HomeHeroItem) -> some View {
        if let descriptor = SourceRegistry.descriptor(for: item.drama.source) {
            NavigationLink {
                DetailView(provider: descriptor.provider, drama: item.drama)
            } label: {
                HomeHeroCard(item: item)
            }
            .buttonStyle(AppPressStyle(scale: 0.99))
        } else {
            HomeHeroCard(item: item)
        }
    }

    #if os(macOS)
    private func heroStepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 34, height: 54)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(AppTheme.stroke, lineWidth: 0.8))
        }
        .buttonStyle(AppPressStyle())
    }

    private func stepHero(by delta: Int) {
        guard !model.heroItems.isEmpty else { return }
        let count = model.heroItems.count
        withAnimation(AppTheme.hero) {
            heroIndex = (heroIndex + delta + count) % count
        }
    }
    #endif

    private var featureFallback: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AppMark(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("欢迎回来")
                        .font(.appTitle(22))
                    Text("浏览站源，或者从下面的继续观看接着看")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            if let message = model.errorMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .solidCard()
    }

    // MARK: - 继续观看

    @ViewBuilder
    private var continueWatchingSection: some View {
        let entries = history.entries.sorted { $0.updatedAt > $1.updatedAt }.prefix(8)
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: "继续观看",
                    subtitle: "从上次看到的地方接着看"
                )
                .padding(.horizontal, horizontalPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppTheme.railSpacing) {
                        ForEach(Array(entries)) { entry in
                            if let descriptor = SourceRegistry.descriptor(for: entry.drama.source) {
                                NavigationLink {
                                    DetailView(provider: descriptor.provider, drama: entry.drama)
                                } label: {
                                    ContinueWatchingCard(entry: entry, width: stillWidth)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                }
            }
            .padding(.top, AppTheme.railTopInset)
        }
    }

    // MARK: - 站源

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("站源")
                        .font(.appSection())
                    Text("\(model.sources.count) 个可浏览站源")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
                Button {
                    showingSources = true
                } label: {
                    HStack(spacing: 3) {
                        Text("管理")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.railSpacing) {
                    ForEach(model.sources) { descriptor in
                        NavigationLink {
                            DiscoverView(provider: descriptor.provider)
                        } label: {
                            SourceTile(descriptor: descriptor, width: stillWidth)
                        }
                        .buttonStyle(.plain)
                    }

                    if !lock.isUnlockedThisLaunch {
                        Button {
                            showingLockSheet = true
                        } label: {
                            lockedSourceTile
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
            }
        }
        .padding(.top, AppTheme.railTopInset)
    }

    private var lockedSourceTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.55))
            }
            .frame(width: stillWidth, height: stillWidth * 9 / 16)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.posterRadius, style: .continuous)
                    .strokeBorder(AppTheme.stroke, lineWidth: 0.6)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("更多站源")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("密码解锁 \(model.hiddenSourceCount) 个隐藏站源")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.top, 10)
        }
        .frame(width: stillWidth, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: - 推荐栏

    @ViewBuilder
    private var shelfSections: some View {
        ForEach(model.shelves) { shelf in
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: shelf.title, subtitle: shelf.subtitle)
                    .padding(.horizontal, horizontalPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppTheme.railSpacing) {
                        ForEach(shelf.items) { drama in
                            if let descriptor = SourceRegistry.descriptor(for: drama.source) {
                                NavigationLink {
                                    DetailView(provider: descriptor.provider, drama: drama)
                                } label: {
                                    DramaPosterCard(drama: drama, width: posterWidth)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                }
            }
            .padding(.top, AppTheme.railTopInset)
        }

        if model.isLoading && model.shelves.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(radius: 5).frame(width: 92, height: 18)
                    .padding(.horizontal, horizontalPadding)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonPosterCard().frame(width: posterWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("内容来自公开站源，仅供个人学习与自用")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)
            Text("Apple 原生播放链路 · 支持画中画 / AirPlay / 后台播放")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.7))
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
    }
}
