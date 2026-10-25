import SwiftUI

struct PXProfileView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var follow = FollowStore.shared
    @ObservedObject private var downloads = DownloadStore.shared
    @ObservedObject private var player = PXPlayerPreferences.shared
    @ObservedObject private var bangumi = PXBangumiCoordinator.shared
    @ObservedObject private var moviePilot = PXMoviePilotCoordinator.shared

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header(width: proxy.size.width)
                    stats
                    shortcuts
                    integrations
                    recent
                }
                .padding(.top, PXPlatform.isMac ? 20 : 8)
                .padding(.bottom, 36)
            }
        }
        .background(PXPageBackground())
        .navigationTitle("我的")
        .pxHiddenNavigationBar()
        .onAppear { downloads.startPolling() }
        .onDisappear { downloads.stopPolling() }
    }

    private func header(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(PXTheme.accentGradient)
                Text("PX")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.82))
            }
            .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text("本地用户")
                    .font(PXFont.title(21))
                    .foregroundStyle(PXTheme.textPrimary)
                Text("PlayerX \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    .font(PXFont.mono(9))
                    .foregroundStyle(PXTheme.textTertiary)
            }
            Spacer()
            NavigationLink { PXSettingsHomeView() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(PXIconButtonStyle(size: 40))
        }
        .padding(.horizontal, PXTheme.padding(for: width))
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat(value: "\(history.entries.count)", title: "观看记录")
            stat(value: "\(follow.entries.count)", title: "收藏")
            stat(value: "\(downloads.completedJobs.count)", title: "已下载")
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private func stat(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(PXFont.display(24)).foregroundStyle(PXTheme.textPrimary)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pxFlatCard()
    }

    private var shortcuts: some View {
        PXSettingsSection(title: "内容") {
            NavigationLink { PXFollowView() } label: {
                PXSettingsRow(symbol: "heart.text.square", title: "我的追剧", subtitle: "想看 / 在看 / 已看", value: "\(follow.entries.count)")
            }
            .buttonStyle(.plain)
            Divider().overlay(PXTheme.stroke)
            NavigationLink { PXDownloadsView() } label: {
                PXSettingsRow(symbol: "arrow.down.circle", title: "下载与缓存", subtitle: "离线剧集与磁盘管理", value: "\(downloads.jobs.count)")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }

    private var integrations: some View {
        PXSettingsSection(title: "服务") {
            NavigationLink { PXBangumiSettingsView() } label: {
                PXSettingsRow(symbol: "calendar", title: "Bangumi", subtitle: bangumi.isLoggedIn ? "已登录 · 追番同步" : "登录后同步收藏", value: bangumi.isLoggedIn ? "在线" : nil, tint: PXTheme.rose)
            }
            .buttonStyle(.plain)
            Divider().overlay(PXTheme.stroke)
            NavigationLink { PXMoviePilotSettingsView() } label: {
                PXSettingsRow(symbol: "paperplane", title: "MoviePilot", subtitle: moviePilot.isLoggedIn ? "已连接 · 找片/下载/订阅" : "连接自建找片服务", value: moviePilot.isLoggedIn ? "在线" : nil, tint: PXTheme.sky)
            }
            .buttonStyle(.plain)
            Divider().overlay(PXTheme.stroke)
            NavigationLink { PXPlaybackSettingsView() } label: {
                PXSettingsRow(symbol: "bolt", title: "播放内核", subtitle: "Pillarbox / Erika / 原生", value: player.engine.title)
            }
            .buttonStyle(.plain)
            Divider().overlay(PXTheme.stroke)
            NavigationLink { PXSettingsHomeView() } label: {
                PXSettingsRow(symbol: "gearshape", title: "全部设置")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PXTheme.contentPadding)
    }

    @ViewBuilder
    private var recent: some View {
        if !history.entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                PXSectionHeader(title: "最近观看", subtitle: nil, symbol: "clock")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(history.entries.prefix(10)) { entry in
                            if let descriptor = SourceRegistry.descriptor(for: entry.drama.source) {
                                NavigationLink {
                                    PXDetailView(entry: PXCatalogEntry(drama: entry.drama, section: .library, providerID: descriptor.id), resume: entry)
                                } label: {
                                    PXContinueCard(entry: entry, width: 240)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, PXTheme.contentPadding)
        }
    }
}
