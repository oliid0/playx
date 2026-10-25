import SwiftUI

struct PXSourceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PXSourceConfigurationStore.shared
    @State private var draft: PXSourceConfiguration
    @State private var isTesting = false
    @State private var isSaving = false
    @State private var testResult: PXSourceTestResult?
    @State private var errorMessage: String?
    private let isNew: Bool

    init(configuration: PXSourceConfiguration) {
        _draft = State(initialValue: configuration)
        self.isNew = !PXSourceConfigurationStore.shared.configurations.contains { $0.id == configuration.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    kindSection
                    connectionSection
                    if draft.kind.isWebDAV {
                        pathSection
                    }
                    if draft.kind == .maccms {
                        maccmsSection
                    }
                    if draft.kind.isMediaServer {
                        credentialsSection
                    }
                    testSection
                    if let errorMessage {
                        PXErrorBanner(message: errorMessage)
                    }
                }
                .padding(20)
            }
            .background(PXPageBackground())
            .navigationTitle(isNew ? "添加媒体源" : "编辑媒体源")
            .pxInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView().controlSize(.small) } else { Text("保存") }
                    }
                    .disabled(!canSave || isSaving || isTesting)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var canSave: Bool {
        guard draft.normalizedBaseURL != nil else { return false }
        if draft.kind.isMediaServer { return !draft.token.isEmpty && !draft.userID.isEmpty }
        if draft.kind.isWebDAV { return !draft.username.isEmpty }
        return true
    }

    private var kindSection: some View {
        PXSettingsSection(title: "类型") {
            HStack(spacing: 11) {
                Image(systemName: draft.kind.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PXTheme.accent)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.kind.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(PXTheme.textPrimary)
                    Text(draft.kind.hint).font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                }
                Spacer()
                if isNew {
                    Picker("", selection: $draft.kind) {
                        ForEach([PXSourceKind.jellyfin, .emby, .webdav, .nas, .alist, .maccms]) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .labelsHidden()
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var connectionSection: some View {
        PXSettingsSection(title: "连接") {
            field("显示名称", text: $draft.name, prompt: draft.kind.title)
            divider
            field("服务器地址", text: $draft.baseURL, prompt: "https://host:port")
            if let url = draft.normalizedBaseURL {
                Text("最终地址：\(url.absoluteString)")
                    .font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                    .padding(.bottom, 8)
            }
        }
    }

    private var credentialsSection: some View {
        PXSettingsSection(title: "账号") {
            field("用户名", text: $draft.username, prompt: "媒体服务器用户名")
            divider
            secureField("密码", text: $draft.password, prompt: "媒体服务器密码")
            if !draft.token.isEmpty {
                Text("已登录 · \(draft.userID)")
                    .font(.system(size: 9)).foregroundStyle(PXTheme.mint)
                    .padding(.vertical, 6)
                Button("清除登录状态") {
                    draft.token = ""
                    draft.userID = ""
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PXTheme.warning)
                .buttonStyle(.plain)
            }
        }
    }

    private var pathSection: some View {
        PXSettingsSection(title: "WebDAV") {
            field("用户名", text: $draft.username, prompt: "WebDAV 用户名")
            divider
            secureField("密码", text: $draft.password, prompt: "WebDAV 密码")
            divider
            field("根目录", text: $draft.rootPath, prompt: "/")
        }
    }

    private var maccmsSection: some View {
        PXSettingsSection(title: "MacCMS API") {
            field("API 路径", text: $draft.apiPath, prompt: "api.php/provide/vod/")
            Text("通常是 /api.php/provide/vod/，不同 CMS 可能不同。")
                .font(.system(size: 9)).foregroundStyle(PXTheme.textTertiary)
                .padding(.bottom, 8)
        }
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task { await test() }
            } label: {
                HStack {
                    if isTesting { ProgressView().controlSize(.small) }
                    Image(systemName: "bolt.horizontal")
                    Text(isTesting ? "正在测试" : "测试连接")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PXSecondaryButtonStyle())
            .disabled(isTesting || draft.normalizedBaseURL == nil)

            if let testResult {
                VStack(alignment: .leading, spacing: 2) {
                    Text(testResult.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(PXTheme.mint)
                    Text(testResult.detail).font(.system(size: 10)).foregroundStyle(PXTheme.textSecondary)
                }
                .pxFlatCard()
            }
        }
    }

    private var divider: some View { Divider().overlay(PXTheme.stroke) }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(PXTheme.textPrimary)
                .padding(.vertical, 8)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
        }
    }

    private func secureField(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(PXTheme.textTertiary)
            SecureField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(PXTheme.textPrimary)
                .padding(.vertical, 8)
        }
    }

    private func test() async {
        isTesting = true
        errorMessage = nil
        defer { isTesting = false }
        do {
            if draft.kind.isMediaServer, !draft.username.isEmpty {
                draft = try await PXSourceLoginService.authenticate(draft)
            }
            testResult = try await PXSourceLoginService.test(draft)
        } catch {
            errorMessage = error.localizedDescription
            testResult = nil
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            if draft.kind.isMediaServer, draft.token.isEmpty {
                draft = try await PXSourceLoginService.authenticate(draft)
            }
            if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.name = draft.displayName
            }
            _ = store.upsert(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
