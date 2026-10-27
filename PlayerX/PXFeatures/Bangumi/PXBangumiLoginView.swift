import SwiftUI

struct PXBangumiLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = PXBangumiCoordinator.shared
    @ObservedObject private var settings = PXAppSettings.shared
    @State private var token = ""
    @State private var username = ""
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            SettingsGlassPage {
                SettingsGlassSection("账号") {
                    SettingsTextRow("Access Token", text: $token, prompt: "粘贴 Bangumi access_token", isSecure: true)
                    SettingsGlassDivider()
                    SettingsTextRow("用户名", text: $username, prompt: "bangumi 用户名（可选）")
                    SettingsNote("在 bgm.tv 的第三方应用授权页获取 access_token。令牌仅保存在本机。")
                }

                if let user = coordinator.profile {
                    SettingsGlassSection("当前账号") {
                        HStack(spacing: 12) {
                            PXRemoteImage(url: user.avatar?.best, maxPixel: 160)
                                .frame(width: 44, height: 44).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName).font(.body.weight(.semibold))
                                Text("@\(user.username)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .settingsRow()
                    }
                }

                if let error = coordinator.errorMessage {
                    SettingsInlineError(message: error)
                }

                SettingsGlassSection {
                    SettingsActionRow(isWorking ? "正在登录…" : "登录", systemImage: "person.badge.key") {
                        Task {
                            isWorking = true
                            await coordinator.login(token: token, username: username)
                            isWorking = false
                            if coordinator.profile != nil { dismiss() }
                        }
                    }
                    .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
                    if coordinator.isLoggedIn {
                        SettingsGlassDivider()
                        SettingsActionRow("退出 Bangumi", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            coordinator.logout()
                            dismiss()
                        }
                    }
                }
            }
            .background(PXPageBackground())
            .navigationTitle("Bangumi 账号")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } }
            }
            .onAppear {
                token = settings.bangumiAccessToken
                username = settings.bangumiUsername
            }
        }
        .preferredColorScheme(.dark)
    }
}
