import SwiftUI

struct PXMoviePilotHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var query = ""
    @State private var tab = 0
    @State private var showLogin = false

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header(width: proxy.size.width)
                    if !coordinator.isLoggedIn {
                        loginCard
                            .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                            .padding(.top, 16)
                    } else {
                        searchBox(width: proxy.size.width)
                        Picker("", selection: $tab) {
                            Text("找片").tag(0)
                            Text("订阅").tag(1)
                            Text("下载").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                        .padding(.top, 12)
                        switch tab {
                        case 0: results(width: proxy.size.width)
                        case 1: PXMoviePilotSubscriptionsView()
                        default: PXMoviePilotDownloadsView()
                        }
                    }
                    if let error = coordinator.errorMessage {
                        PXErrorBanner(message: error)
                            .padding(.horizontal, PXTheme.padding(for: proxy.size.width))
                            .padding(.top, 12)
                    }
                }
                .padding(.bottom, 32)
            }
            .refreshable {
                await coordinator.reloadAll()
                if !query.isEmpty { await coordinator.searchMedia(query) }
            }
        }
        .background(PXPageBackground())
        .navigationTitle("找片")
        .pxHiddenNavigationBar()
        .task {
            await coordinator.restoreSession()
            coordinator.startPolling()
        }
        .onDisappear { coordinator.stopPolling() }
    }

    private func header(width: CGFloat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MoviePilot")
                    .font(PXFont.display(32))
                    .foregroundStyle(PXTheme.textPrimary)
                Text("搜索资源 · 添加下载 · 订阅追更")
                    .font(PXFont.caption(11))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
            if coordinator.isLoggedIn {
                Button { showLogin = true } label: {
                    PXRemoteImage(url: coordinator.user?.avatar.flatMap { URL(string: $0) }, maxPixel: 100)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(PXTheme.stroke))
                        .overlay {
                            if coordinator.user?.avatar == nil {
                                Image(systemName: "person.crop.circle").foregroundStyle(PXTheme.textSecondary)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, PXTheme.padding(for: width))
        .padding(.top, PXPlatform.isMac ? 20 : 8)
        .sheet(isPresented: $showLogin) {
            PXMoviePilotLoginView()
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(PXTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("连接 MoviePilot")
                        .font(PXFont.title(19))
                        .foregroundStyle(PXTheme.textPrimary)
                    Text("在 MoviePilot 中搜索站点资源、添加下载和订阅。")
                        .font(.system(size: 10))
                        .foregroundStyle(PXTheme.textTertiary)
                }
            }
            Button { showLogin = true } label: {
                Text("配置服务器").frame(maxWidth: .infinity)
            }
            .buttonStyle(PXPrimaryButtonStyle())
        }
        .pxGlassCard()
    }

    private func searchBox(width: CGFloat) -> some View {
        HStack(spacing: 9) {
            PXSearchField(text: $query, prompt: "搜索电影、剧集（中文 / 英文 / 原名）") {
                Task { await coordinator.searchMedia(query) }
            }
            Button {
                Task { await coordinator.searchMedia(query) }
            } label: {
                Image(systemName: "arrow.right")
            }
            .buttonStyle(PXIconButtonStyle(size: 44))
        }
        .padding(.horizontal, PXTheme.padding(for: width))
        .padding(.top, 16)
    }

    @ViewBuilder
    private func results(width: CGFloat) -> some View {
        if coordinator.isLoading {
            PXLoadingCard()
        } else if coordinator.mediaResults.isEmpty {
            PXEmptyState(
                title: "开始找片",
                message: "输入片名，MoviePilot 会聚合 TMDB / 豆瓣 / Bangumi 的媒体信息。",
                symbol: "magnifyingglass"
            )
        } else {
            LazyVStack(spacing: 10) {
                ForEach(coordinator.mediaResults) { media in
                    NavigationLink {
                        PXMoviePilotResourceView(media: media)
                    } label: {
                        PXMoviePilotMediaCard(media: media)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PXTheme.padding(for: width))
            .padding(.top, 14)
        }
    }
}

struct PXMoviePilotLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var baseURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var working = false

    var body: some View {
        NavigationStack {
            SettingsGlassPage {
                SettingsGlassSection("服务器") {
                    SettingsTextRow("地址", text: $baseURL, prompt: "https://moviepilot.example.com")
                    SettingsGlassDivider()
                    SettingsTextRow("用户名", text: $username, prompt: "MoviePilot 用户名")
                    SettingsGlassDivider()
                    SettingsTextRow("密码", text: $password, prompt: "MoviePilot 密码", isSecure: true)
                    SettingsNote("凭证只保存在本机 UserDefaults；JWT 由服务器签发。")
                }

                if let error = coordinator.errorMessage {
                    SettingsInlineError(message: error)
                }

                SettingsGlassSection {
                    SettingsActionRow(working ? "正在登录…" : "登录", systemImage: "person.badge.key") {
                        Task {
                            working = true
                            await coordinator.login(username: username, password: password, baseURL: baseURL)
                            working = false
                            if coordinator.isLoggedIn { dismiss() }
                        }
                    }
                    .disabled(baseURL.isEmpty || username.isEmpty || password.isEmpty || working)
                    if coordinator.isLoggedIn {
                        SettingsGlassDivider()
                        SettingsActionRow("退出登录", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            coordinator.logout()
                            dismiss()
                        }
                    }
                }
            }
            .background(PXPageBackground())
            .navigationTitle("MoviePilot 账号")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .onAppear {
                baseURL = settings.moviePilotURL
                username = settings.moviePilotUsername
                password = settings.moviePilotPassword
            }
        }
        .preferredColorScheme(.dark)
    }
}
