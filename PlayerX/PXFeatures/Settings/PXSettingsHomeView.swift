import SwiftUI
import PlayXUI

/// 设置 hub：严格沿用 OcPlayer 的 `SettingsGlassPage` 卡片流和分组。
/// 行只负责导航与当前值预览，具体控件在子页。
struct PXSettingsHomeView: View {
    @EnvironmentObject private var app: PXAppState
    @ObservedObject private var player = PXPlayerPreferences.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var bangumi = PXBangumiCoordinator.shared
    @ObservedObject private var moviePilot = PXMoviePilotCoordinator.shared
    @ObservedObject private var sources = PXSourceConfigurationStore.shared
    @ObservedObject private var downloads = DownloadStore.shared

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("服务") {
                SettingsNavLink(title: "媒体服务器与站源", systemImage: "server.rack", value: sourceValue) {
                    PXSourceSettingsView()
                        .environmentObject(app)
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "Bangumi", icon: .brand(name: "bangumi-logo", aspect: 0.94), value: bangumiValue) {
                    PXBangumiSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "MoviePilot", icon: .brand(name: "moviepilot-logo", aspect: 0.86), value: moviePilotValue) {
                    PXMoviePilotSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "TMDB 元数据补全", icon: .brand(name: "tmdb-logo", aspect: 2.33), value: settings.tmdbEnabled ? "已启用" : "未启用") {
                    PXTMDbSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "网络", systemImage: "globe", value: settings.customUserAgent.isEmpty ? "默认 UA" : "自定义 UA") {
                    PXNetworkSettingsView()
                }
            }

            SettingsGlassSection("播放与界面") {
                SettingsNavLink(title: "播放", systemImage: "play.circle", value: player.engine.title) {
                    PXPlaybackSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "弹幕", systemImage: "text.bubble", value: player.danmakuEnabled ? "自动加载" : "已关闭") {
                    PXDanmakuSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "首页栏目", systemImage: "square.grid.2x2", value: homeSectionsValue) {
                    PXHomeSectionsSettingsView()
                }
            }

            SettingsGlassSection("应用") {
                SettingsNavLink(title: "下载", systemImage: "arrow.down.circle", value: downloads.jobs.isEmpty ? "无任务" : "\(downloads.jobs.count) 个任务") {
                    PXDownloadsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "维护", systemImage: "wrench.and.screwdriver", value: nil) {
                    PXMaintenanceSettingsView()
                }
                SettingsGlassDivider()
                SettingsNavLink(title: "关于", systemImage: "info.circle", value: PXBundleInfo.version) {
                    PXAboutView()
                }
            }

            Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(PXPageBackground())
        .navigationTitle("")
        .pxInlineNavigationTitle()
        .task { await downloads.refresh() }
    }

    private var sourceValue: String {
        let external = sources.enabledConfigurations.count
        let stations = PXCatalogService.shared.visibleSources.filter { !$0.isExternal }.count
        if external == 0 { return "\(stations) 个站源" }
        return "\(stations) 站源 · \(external) 外部"
    }

    private var bangumiValue: String {
        guard settings.bangumiEnabled else { return "已关闭" }
        return bangumi.isLoggedIn ? (bangumi.profile?.displayName ?? "已登录") : "未登录"
    }

    private var moviePilotValue: String {
        guard settings.moviePilotEnabled else { return "已关闭" }
        return moviePilot.isLoggedIn ? "已登录" : "未配置"
    }

    private var homeSectionsValue: String {
        let hidden = PXHomeSectionPreference.hidden(from: UserDefaults.standard.string(forKey: PXHomeSectionPreference.storageKey) ?? "")
        return hidden.isEmpty ? "显示 4 栏" : "显示 \(4 - hidden.count)/4 栏"
    }
}
