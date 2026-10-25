import SwiftUI

struct PXBangumiSettingsView: View {
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var showLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "账号") {
                    if let profile = coordinator.profile {
                        HStack(spacing: 11) {
                            PXRemoteImage(url: profile.avatar?.best, maxPixel: 160)
                                .frame(width: 46, height: 46).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                                Text("@\(profile.username)").font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                            }
                            Spacer()
                            Button("切换") { showLogin = true }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(PXTheme.accent)
                        }
                        .padding(.vertical, 9)
                    } else {
                        Button {
                            showLogin = true
                        } label: {
                            PXSettingsRow(symbol: "person.badge.key", title: "登录 Bangumi", subtitle: "使用 access_token 同步收藏与进度")
                        }
                        .buttonStyle(.plain)
                    }
                }
                PXSettingsSection(title: "偏好") {
                    ToggleRow(title: "启用 Bangumi", subtitle: "在标签栏显示追番分区", isOn: $settings.bangumiEnabled)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "优先中文名", subtitle: "显示条目时优先 name_cn", isOn: $settings.bangumiPreferChinese)
                    Divider().overlay(PXTheme.stroke)
                    HStack {
                        Text("用户名").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Text(settings.bangumiUsername.isEmpty ? "未设置" : settings.bangumiUsername)
                            .font(.system(size: 11)).foregroundStyle(PXTheme.textTertiary)
                    }
                    .padding(.vertical, 8)
                }
                if let error = coordinator.errorMessage {
                    PXErrorBanner(message: error)
                }
                Button("打开 Bangumi 分区") {
                    // 由根导航处理；设置页只负责关闭当前层。
                }
                .buttonStyle(PXSecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("Bangumi")
        .pxInlineNavigationTitle()
        .sheet(isPresented: $showLogin) { PXBangumiLoginView() }
        .task { await coordinator.restoreSession() }
    }
}
