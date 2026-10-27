import SwiftUI

struct PXMoviePilotSettingsView: View {
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var showLogin = false

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("服务器") {
                if coordinator.isLoggedIn {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(PXTheme.mint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(coordinator.user?.name ?? "已连接").font(.body.weight(.semibold))
                            Text(settings.moviePilotURL).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .settingsRow()
                    SettingsGlassDivider()
                    SettingsActionRow("切换账号", systemImage: "person.badge.key") { showLogin = true }
                    SettingsGlassDivider()
                    SettingsActionRow("退出登录", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        coordinator.logout()
                    }
                } else {
                    SettingsActionRow("连接 MoviePilot", systemImage: "person.badge.key") { showLogin = true }
                    SettingsNote("填写自建 MoviePilot 地址、用户名和密码；凭证只保存在本机。")
                }
            }

            SettingsGlassSection("功能") {
                Toggle("启用 MoviePilot 分区", isOn: $settings.moviePilotEnabled)
                SettingsGlassDivider()
                Toggle("下载进度后台轮询", isOn: .constant(true))
                SettingsNote("找片页打开时每 5 秒刷新下载任务。")
            }

            if let error = coordinator.errorMessage {
                SettingsInlineError(message: error)
            }

            SettingsGlassSection("关于") {
                SettingsNote("资源搜索由 MoviePilot 服务端聚合站点完成；PlayerX 只负责展示与提交下载/订阅。")
            }
        }
        .navigationTitle("MoviePilot")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLogin) { PXMoviePilotLoginView() }
    }
}
