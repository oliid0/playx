import SwiftUI

struct PXMaintenanceSettingsView: View {
    @State private var message: String?

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("缓存") {
                SettingsActionRow("清除图片缓存", systemImage: "photo.on.rectangle") {
                    PXImageMemoryCache.shared.clear()
                    URLCache.shared.removeAllCachedResponses()
                    message = "图片缓存已清除"
                }
                SettingsGlassDivider()
                SettingsActionRow("清除 TMDB 缓存", systemImage: "sparkles.tv") {
                    Task {
                        await PXMetadataCache.shared.clearAll()
                        message = "TMDB 缓存已清除"
                    }
                }
                SettingsGlassDivider()
                SettingsActionRow("清除搜索历史", systemImage: "clock") {
                    PXSearchHistoryStore.shared.clear()
                    message = "搜索历史已清除"
                }
            }

            SettingsGlassSection("数据") {
                SettingsActionRow("重新加载外部媒体源", systemImage: "arrow.clockwise") {
                    PXSourceConfigurationStore.shared.refreshRegistry()
                    message = "媒体源已刷新"
                }
            }

            if let message {
                SettingsNote(message)
            }

            SettingsGlassSection("诊断") {
                SettingsNote("PlayerX \(PXBundleInfo.version) (\(PXBundleInfo.build)) · \(PXDeviceInfo.name) · \(PXDeviceInfo.system)")
                SettingsNote("内核：\(PXPlayerPreferences.shared.engine.title)")
                SettingsNote("TMDB：\(PXAppSettings.shared.tmdbEnabled ? "开启" : "关闭") · 外部源：\(PXSourceConfigurationStore.shared.enabledConfigurations.count)")
            }
        }
        .navigationTitle("维护")
        .pxInlineNavigationTitle()
    }
}
