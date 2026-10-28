import SwiftUI
import PlayXUI

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
            SettingsGlassPage {
                SettingsGlassSection("类型") {
                    HStack(spacing: SettingsMetrics.iconLabelSpacing) {
                        Image(systemName: draft.kind.symbol)
                            .font(.system(size: SettingsMetrics.iconGlyphSize))
                            .frame(width: SettingsMetrics.iconColumnWidth)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.kind.title)
                            Text(draft.kind.hint).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isNew {
                            Picker("类型", selection: $draft.kind) {
                                ForEach([PXSourceKind.jellyfin, .emby, .webdav, .nas, .alist, .maccms]) { kind in
                                    Text(kind.title).tag(kind)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                    }
                    .settingsRow()
                }

                SettingsGlassSection("连接") {
                    SettingsTextRow("显示名称", text: $draft.name, prompt: draft.kind.title)
                    SettingsGlassDivider()
                    SettingsTextRow("服务器地址", text: $draft.baseURL, prompt: "https://host:port")
                    if let url = draft.normalizedBaseURL {
                        SettingsNote("最终地址：\(url.absoluteString)")
                    }
                }

                if draft.kind.isMediaServer {
                    SettingsGlassSection("账号") {
                        SettingsTextRow("用户名", text: $draft.username, prompt: "媒体服务器用户名")
                        SettingsGlassDivider()
                        SettingsTextRow("密码", text: $draft.password, prompt: "媒体服务器密码", isSecure: true)
                        if !draft.token.isEmpty {
                            SettingsNote("已登录 · \(draft.userID)")
                            SettingsGlassDivider()
                            SettingsActionRow("清除登录状态", systemImage: "xmark.circle", role: .destructive) {
                                draft.token = ""
                                draft.userID = ""
                            }
                        }
                    }
                }

                if draft.kind.isWebDAV {
                    SettingsGlassSection("WebDAV") {
                        SettingsTextRow("用户名", text: $draft.username, prompt: "WebDAV 用户名")
                        SettingsGlassDivider()
                        SettingsTextRow("密码", text: $draft.password, prompt: "WebDAV 密码", isSecure: true)
                        SettingsGlassDivider()
                        SettingsTextRow("根目录", text: $draft.rootPath, prompt: "/")
                    }
                }

                if draft.kind == .maccms {
                    SettingsGlassSection("MacCMS API") {
                        SettingsTextRow("API 路径", text: $draft.apiPath, prompt: "api.php/provide/vod/")
                        SettingsNote("常见为 /api.php/provide/vod/；不同 CMS 可能不同。")
                    }
                }

                SettingsGlassSection("验证") {
                    SettingsActionRow(isTesting ? "正在测试…" : "测试连接", systemImage: "bolt.horizontal") {
                        Task { await test() }
                    }
                    .disabled(isTesting || draft.normalizedBaseURL == nil)
                    if let testResult {
                        SettingsNote("\(testResult.title) · \(testResult.detail)")
                    }
                }

                if let errorMessage {
                    SettingsInlineError(message: errorMessage)
                }
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
