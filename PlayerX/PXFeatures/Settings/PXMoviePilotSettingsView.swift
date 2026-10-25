import SwiftUI

struct PXMoviePilotSettingsView: View {
    @ObservedObject private var coordinator = PXMoviePilotCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var showLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "服务器") {
                    if coordinator.isLoggedIn {
                        PXSettingsRow(
                            symbol: "checkmark.seal.fill",
                            title: coordinator.user?.name ?? "已连接",
                            subtitle: settings.moviePilotURL,
                            value: "在线",
                            tint: PXTheme.mint
                        )
                        Divider().overlay(PXTheme.stroke)
                    }
                    Button {
                        showLogin = true
                    } label: {
                        PXSettingsRow(
                            symbol: "person.badge.key",
                            title: coordinator.isLoggedIn ? "切换账号" : "连接 MoviePilot",
                            subtitle: "地址 / 用户名 / 密码",
                            value: coordinator.isLoggedIn ? "已登录" : "未登录"
                        )
                    }
                    .buttonStyle(.plain)
                }
                PXSettingsSection(title: "功能") {
                    ToggleRow(title: "启用 MoviePilot", subtitle: "在标签栏显示找片分区", isOn: $settings.moviePilotEnabled)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "后台轮询下载", subtitle: "找片页打开时每 5 秒刷新进度", isOn: .constant(true))
                }
                if let error = coordinator.errorMessage {
                    PXErrorBanner(message: error)
                }
                Text("MoviePilot 是自建服务；地址与凭证只保存在本机。资源搜索走服务端站点聚合。")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("MoviePilot")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLogin) { PXMoviePilotLoginView() }
    }
}
