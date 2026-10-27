import SwiftUI

struct PXTMDbSettingsView: View {
    @ObservedObject private var settings = PXAppSettings.shared
    @ObservedObject private var metadata = PXMetadataCoordinator.shared
    @State private var revealToken = false

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("TMDB") {
                Toggle("启用元数据补全", isOn: $settings.tmdbEnabled)
                SettingsNote("关闭后详情页只显示站源自己的标题、简介与集数。")
                SettingsGlassDivider()
                Toggle("自动匹配", isOn: $settings.autoMatchMetadata)
                SettingsGlassDivider()
                SettingsPickerRow("语言", selection: $settings.tmdbLanguage) {
                    ForEach(PXLanguageOption.all) { option in
                        Text(option.title).tag(option.code)
                    }
                }
            }

            SettingsGlassSection("访问令牌") {
                if revealToken {
                    SettingsTextRow("Token", text: $settings.tmdbToken)
                } else {
                    SettingsTextRow("Token", text: $settings.tmdbToken, isSecure: true)
                }
                SettingsGlassDivider()
                SettingsActionRow(revealToken ? "隐藏 Token" : "显示 Token", systemImage: revealToken ? "eye.slash" : "eye") {
                    revealToken.toggle()
                }
                SettingsGlassDivider()
                SettingsActionRow("恢复内置只读 Token", systemImage: "arrow.counterclockwise") {
                    settings.tmdbToken = PXAppSettings.builtInTMDbToken
                }
            }

            if let error = metadata.lastError {
                SettingsInlineError(message: error)
            }

            SettingsGlassSection("说明") {
                SettingsNote("内置 Token 只有 api_read 权限，仅用于 api.themoviedb.org。元数据缓存只写本机，不写入日志。")
                SettingsNote("This product uses the TMDB API but is not endorsed or certified by TMDB.")
            }
        }
        .navigationTitle("TMDB 元数据补全")
        .pxInlineNavigationTitle()
    }
}
