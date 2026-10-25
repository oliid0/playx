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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bangumi 访问令牌").font(.system(size: 12, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
                        SecureField("粘贴 access_token", text: $token)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke))
                        Text("在 bgm.tv 的第三方应用授权页获取 access_token。令牌仅保存在本机。")
                            .font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户名（可选）").font(.system(size: 12, weight: .semibold)).foregroundStyle(PXTheme.textSecondary)
                        TextField("bangumi 用户名", text: $username)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(PXTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(PXTheme.stroke))
                    }
                    if let user = coordinator.profile {
                        HStack(spacing: 10) {
                            PXRemoteImage(url: user.avatar?.best, maxPixel: 120)
                                .frame(width: 44, height: 44).clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                                Text("@\(user.username)").font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .pxFlatCard()
                    }
                    if let error = coordinator.errorMessage {
                        PXErrorBanner(message: error)
                    }
                    Button {
                        Task {
                            isWorking = true
                            await coordinator.login(token: token, username: username)
                            isWorking = false
                            if coordinator.profile != nil { dismiss() }
                        }
                    } label: {
                        HStack {
                            if isWorking { ProgressView().controlSize(.small) }
                            Text("登录")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PXPrimaryButtonStyle())
                    .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
                    if coordinator.isLoggedIn {
                        Button("退出 Bangumi", role: .destructive) {
                            coordinator.logout()
                            dismiss()
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PXTheme.danger)
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle("Bangumi 账号")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                token = settings.bangumiAccessToken
                username = settings.bangumiUsername
            }
        }
        .preferredColorScheme(.dark)
    }
}
