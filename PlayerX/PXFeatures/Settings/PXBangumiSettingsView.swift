import SwiftUI
import PlayXUI

struct PXBangumiSettingsView: View {
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var showLogin = false

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("账号") {
                if let profile = coordinator.profile {
                    HStack(spacing: 12) {
                        PXRemoteImage(url: profile.avatar?.best, maxPixel: 160)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(PXTheme.stroke))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName).font(.body.weight(.semibold))
                            Text("@\(profile.username)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("切换") { showLogin = true }
                            .buttonStyle(.bordered)
                    }
                    .settingsRow()
                    SettingsGlassDivider()
                    SettingsActionRow("退出 Bangumi", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        coordinator.logout()
                    }
                } else {
                    SettingsActionRow("登录 Bangumi", systemImage: "person.badge.key") {
                        showLogin = true
                    }
                    SettingsNote("使用 Bangumi 个人 access_token。登录后可同步想看/在看/看过与单集进度。")
                }
            }

            SettingsGlassSection("显示") {
                Toggle("启用 Bangumi 分区", isOn: $settings.bangumiEnabled)
                SettingsGlassDivider()
                Toggle("优先中文名", isOn: $settings.bangumiPreferChinese)
                SettingsGlassDivider()
                HStack {
                    Text("用户名")
                    Spacer()
                    Text(settings.bangumiUsername.isEmpty ? "未设置" : settings.bangumiUsername)
                        .foregroundStyle(.secondary)
                }
                .settingsRow()
            }

            if let error = coordinator.errorMessage {
                SettingsInlineError(message: error)
            }

            SettingsGlassSection("关于") {
                SettingsNote("Bangumi 数据来自 api.bgm.tv。剧集收藏与进度通过官方 v0 API 读写。")
            }
        }
        .navigationTitle("Bangumi")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLogin) { PXBangumiLoginView() }
        .task { await coordinator.restoreSession() }
    }
}
