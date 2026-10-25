import SwiftUI

struct PXTMDbSettingsView: View {
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var metadata = PXMetadataCoordinator.shared
    @State private var showToken = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PXSettingsSection(title: "TMDB") {
                    ToggleRow(title: "启用元数据补全", subtitle: "详情页显示评分、简介、演员表", isOn: $settings.tmdbEnabled)
                    Divider().overlay(PXTheme.stroke)
                    ToggleRow(title: "自动匹配", subtitle: "按标题、年份和类型选择最可能的条目", isOn: $settings.autoMatchMetadata)
                    Divider().overlay(PXTheme.stroke)
                    HStack {
                        Text("语言").font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
                        Spacer()
                        Picker("", selection: $settings.tmdbLanguage) {
                            ForEach(PXLanguageOption.all) { option in
                                Text(option.title).tag(option.code)
                            }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }
                PXSettingsSection(title: "访问令牌") {
                    HStack {
                        Group {
                            if showToken {
                                TextField("TMDB v4 Read Access Token", text: $settings.tmdbToken)
                            } else {
                                SecureField("TMDB v4 Read Access Token", text: $settings.tmdbToken)
                            }
                        }
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundStyle(PXTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 10)
                }
                Text("已内置只读 Token，可直接使用。令牌仅用于 api.themoviedb.org，不写入日志。")
                    .font(.system(size: 10)).foregroundStyle(PXTheme.textTertiary)
                if let error = metadata.lastError {
                    PXErrorBanner(message: error)
                }
                Button {
                    settings.tmdbToken = PXAppSettings.builtInTMDbToken
                } label: {
                    Label("恢复内置 Token", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PXSecondaryButtonStyle())
            }
            .padding(20)
        }
        .background(PXPageBackground())
        .navigationTitle("TMDB")
        .pxInlineNavigationTitle()
    }
}
