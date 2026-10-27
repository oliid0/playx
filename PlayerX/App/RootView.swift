import SwiftUI

/// 与 OcPlayer 对齐的外壳：
/// - iPhone / iPad：底部 Tab「首页 / 追番 / 找片 / 设置 / 搜索」；
/// - macOS：顶部胶囊导航，不另开 Sidebar；
/// - 播放器是根视图上的同窗口覆盖层（macOS 不再用 sheet 新开窗口）。
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
        ZStack {
            shell
            if let request = app.presentedPlayer {
                PXPlayerScreen(request: request)
                    .environmentObject(app)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .environmentObject(app)
        .tint(PXTheme.accent)
        .preferredColorScheme(.dark)
        .animation(PXTheme.standard, value: app.presentedPlayer != nil)
        .sheet(isPresented: $app.searchPresented) {
            PXGlobalSearchView()
                .environmentObject(app)
        }
        .overlay(alignment: .top) {
            if let toast = app.toast {
                PXToast(message: toast)
                    .padding(.top, PXPlatform.isMac ? 14 : 54)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        if !Task.isCancelled { app.toast = nil }
                    }
            }
        }
        .animation(PXTheme.standard, value: app.toast)
        .onReceive(NotificationCenter.default.publisher(for: .playerXOpenSearch)) { _ in
            app.selectedTab = .search
        }
        .onOpenURL { app.handleDeepLink($0) }
        #if os(macOS)
        .toolbar(app.presentedPlayer == nil ? .visible : .hidden, for: .windowToolbar)
        #endif
    }

    @ViewBuilder
    private var shell: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            PXMacTopBar()
            NavigationStack {
                macContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .id(app.selectedTab)
        }
        .background(PXPageBackground())
        #else
        phoneShell
        #endif
    }

    // MARK: - iPhone / iPad

    @ViewBuilder
    private var phoneShell: some View {
        TabView(selection: Binding(
            get: { app.selectedTab },
            set: { app.selectTab($0) }
        )) {
            NavigationStack { PXHomeView() }
                .tabItem { Label(PXTab.home.title, systemImage: PXTab.home.symbol) }
                .tag(PXTab.home)

            if settings.bangumiEnabled {
                NavigationStack { PXBangumiHomeView() }
                    .tabItem {
                        Label {
                            Text(PXTab.bangumi.title)
                        } icon: {
                            Image("bangumi-logo").renderingMode(.template)
                        }
                    }
                    .tag(PXTab.bangumi)
            }

            if settings.moviePilotEnabled {
                NavigationStack { PXMoviePilotHomeView() }
                    .tabItem {
                        Label {
                            Text(PXTab.moviePilot.title)
                        } icon: {
                            Image("moviepilot-logo").renderingMode(.template)
                        }
                    }
                    .tag(PXTab.moviePilot)
            }

            NavigationStack { PXSettingsHomeView() }
                .tabItem { Label(PXTab.settings.title, systemImage: PXTab.settings.symbol) }
                .tag(PXTab.settings)

            NavigationStack { PXGlobalSearchView(embedded: true) }
                .tabItem { Label(PXTab.search.title, systemImage: PXTab.search.symbol) }
                .tag(PXTab.search)
        }
        .tint(PXTheme.accent)
        .onChange(of: settings.bangumiEnabled) { enabled in
            if !enabled, app.selectedTab == .bangumi { app.selectTab(.home) }
        }
        .onChange(of: settings.moviePilotEnabled) { enabled in
            if !enabled, app.selectedTab == .moviePilot { app.selectTab(.home) }
        }
    }

    // MARK: - macOS

    @ViewBuilder
    private var macContent: some View {
        switch app.selectedTab {
        case .home:
            PXHomeView()
        case .bangumi:
            PXBangumiHomeView()
        case .moviePilot:
            PXMoviePilotHomeView()
        case .settings:
            PXSettingsHomeView()
        case .search:
            PXGlobalSearchView(embedded: true)
        }
    }
}
