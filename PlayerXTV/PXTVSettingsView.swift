import SwiftUI

struct PXTVSettingsView: View {
    @EnvironmentObject private var app: PXTVAppState
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var bangumi = PXBangumiCoordinator.shared
    @ObservedObject private var moviePilot = PXMoviePilotCoordinator.shared
    @State private var streamURL = ""
    @State private var showStream = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("设置").font(PXFont.display(44)).foregroundStyle(PXTheme.textPrimary)
                group("播放") {
                    Button("播放 Apple 测试流") { app.playTestStream() }.buttonStyle(.card)
                    Button("打开直链播放") { showStream = true }.buttonStyle(.card)
                    Text("tvOS 使用 Pillarbox + 系统播放器，遥控器提供播放/暂停、快进、字幕与音轨菜单。")
                        .font(.caption).foregroundStyle(PXTheme.textTertiary)
                }
                group("媒体源") {
                    NavigationLink(value: PXTVRoute.sources) {
                        Label("管理 Jellyfin / Emby / WebDAV / MacCMS", systemImage: "externaldrive.connected.to.line.below")
                    }
                    .buttonStyle(.card)
                    Button("刷新媒体源") { app.refreshSources() }
                        .buttonStyle(.card)
                }
                group("元数据") {
                    statusRow("TMDB", settings.tmdbEnabled ? "已启用 · \(settings.tmdbLanguage)" : "已关闭")
                    statusRow("内置只读 Token", settings.effectiveTMDbToken.isEmpty ? "无效" : "已配置")
                    if let error = app.metadata.lastError {
                        Text(error).font(.caption).foregroundStyle(PXTheme.warning)
                    }
                }
                group("服务") {
                    statusRow("Bangumi", bangumi.isLoggedIn ? "已登录 · \(bangumi.profile?.displayName ?? "")" : "未登录")
                    statusRow("MoviePilot", moviePilot.isLoggedIn ? "已连接" : "未连接")
                    Text("账号配置在 iOS / iPadOS / macOS 端完成，TV 共享同一套服务实现。")
                        .font(.caption).foregroundStyle(PXTheme.textTertiary)
                }
                group("关于") {
                    statusRow("PlayerX tvOS", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    statusRow("内核", "Pillarbox / 系统 AVPlayer")
                    statusRow("数据", "TMDB · Bangumi · 弹弹play · MoviePilot")
                }
            }
            .padding(.horizontal, 56)
            .padding(.top, 46)
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showStream) {
            PXTVStreamEntryView(title: "直链播放").environmentObject(app)
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(PXFont.title(22)).foregroundStyle(PXTheme.textPrimary)
            FlowLayout(spacing: 12) { content() }
        }
    }

    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
            Text(value).font(.system(size: 15)).foregroundStyle(PXTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(PXTheme.surfaceMuted, in: Capsule())
    }
}
