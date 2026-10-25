import SwiftUI

/// PlayerX 的新根视图。旧版 RootView 的导航逻辑已经迁到 `PXRootView`：
/// iPhone / iPad 用底部 Tab，macOS 用侧边栏；播放器永远是根覆盖层，
/// 因此详情页、Bangumi、MoviePilot 都可以直接起播，不会被 sheet 裁剪。
struct RootView: View {
    var body: some View {
        PXRootView()
    }
}

struct PXRootView: View {
    @StateObject private var app = PXAppState()
    @ObservedObject private var settings = PXAppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            #if os(macOS)
            macShell
            #else
            phoneShell
            #endif
        }
        .environmentObject(app)
        .tint(PXTheme.accent)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $app.searchPresented) {
            PXGlobalSearchView()
                .environmentObject(app)
        }
        .overlay(alignment: .top) {
            if let toast = app.toast {
                PXToast(message: toast)
                    .padding(.top, PXPlatform.isMac ? 12 : 54)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        if !Task.isCancelled { app.toast = nil }
                    }
            }
        }
        .animation(PXTheme.standard, value: app.toast)
        .onReceive(NotificationCenter.default.publisher(for: .playerXOpenSearch)) { _ in
            app.searchPresented = true
        }
        .onOpenURL { app.handleDeepLink($0) }
        #if os(iOS)
        .fullScreenCover(item: $app.presentedPlayer) { request in
            PXPlayerScreen(request: request)
                .environmentObject(app)
        }
        #else
        .sheet(item: $app.presentedPlayer) { request in
            PXPlayerScreen(request: request)
                .environmentObject(app)
                .frame(minWidth: 980, minHeight: 620)
        }
        #endif
    }

    // MARK: - iPhone / iPad

    @ViewBuilder
    private var phoneShell: some View {
        TabView(selection: Binding(
            get: { app.selectedSection },
            set: { app.select($0) }
        )) {
            NavigationStack {
                PXHomeView()
            }
            .tabItem { Label(PXCatalogSection.home.title, systemImage: PXCatalogSection.home.symbol) }
            .tag(PXCatalogSection.home)

            NavigationStack {
                PXLibraryLandingView()
            }
            .tabItem { Label(PXCatalogSection.library.title, systemImage: PXCatalogSection.library.symbol) }
            .tag(PXCatalogSection.library)

            if settings.bangumiEnabled {
                NavigationStack {
                    PXBangumiHomeView()
                }
                .tabItem { Label(PXCatalogSection.bangumi.title, systemImage: PXCatalogSection.bangumi.symbol) }
                .tag(PXCatalogSection.bangumi)
            }

            if settings.moviePilotEnabled {
                NavigationStack {
                    PXMoviePilotHomeView()
                }
                .tabItem { Label(PXCatalogSection.moviepilot.title, systemImage: PXCatalogSection.moviepilot.symbol) }
                .tag(PXCatalogSection.moviepilot)
            }

            NavigationStack {
                PXProfileView()
            }
            .tabItem { Label(PXCatalogSection.profile.title, systemImage: PXCatalogSection.profile.symbol) }
            .tag(PXCatalogSection.profile)
        }
        .tint(PXTheme.accent)
        .onChange(of: settings.bangumiEnabled) { enabled in
            if !enabled, app.selectedSection == .bangumi { app.selectedSection = .home }
        }
        .onChange(of: settings.moviePilotEnabled) { enabled in
            if !enabled, app.selectedSection == .moviepilot { app.selectedSection = .home }
        }
    }

    // MARK: - macOS

    #if os(macOS)
    private var macShell: some View {
        NavigationSplitView {
            PXMacSidebar(selection: Binding(
                get: { app.selectedSection },
                set: { app.select($0) }
            ))
            .navigationSplitViewColumnWidth(min: 218, ideal: 246, max: 300)
        } detail: {
            NavigationStack {
                macDetail(for: app.selectedSection)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(PXTheme.background)
    }

    @ViewBuilder
    private func macDetail(for section: PXCatalogSection) -> some View {
        switch section {
        case .home: PXHomeView()
        case .movies, .series, .anime, .shorts, .variety, .documentary:
            PXBrowseView(section: section)
        case .library: PXLibraryLandingView()
        case .bangumi: PXBangumiHomeView()
        case .moviepilot: PXMoviePilotHomeView()
        case .downloads: PXDownloadsView()
        case .profile: PXProfileView()
        }
    }
    #endif
}

#if os(macOS)
private struct PXMacSidebar: View {
    @Binding var selection: PXCatalogSection
    @ObservedObject private var settings = PXAppSettings.shared

    private var sections: [PXCatalogSection] {
        var values: [PXCatalogSection] = [.home, .library, .movies, .series, .anime, .shorts]
        if settings.bangumiEnabled { values.append(.bangumi) }
        if settings.moviePilotEnabled { values.append(.moviepilot) }
        values.append(contentsOf: [.downloads, .profile])
        return values
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                PXLogoMark(size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text("PlayerX")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text("多站源影院")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(PXTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(sections) { section in
                        Button {
                            selection = section
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: section.symbol)
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(width: 20)
                                Text(section.title)
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                            }
                            .foregroundStyle(selection == section ? PXTheme.accent : PXTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(
                                selection == section ? PXTheme.accent.opacity(0.10) : .clear,
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }
            Spacer()
            Text("Pillarbox / Erika / AVPlayer")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(PXTheme.textTertiary)
                .padding(.bottom, 12)
        }
        .background(PXTheme.backgroundLift.opacity(0.42))
        .navigationTitle("PlayerX")
    }
}
#endif
