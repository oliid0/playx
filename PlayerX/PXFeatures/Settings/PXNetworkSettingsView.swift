import SwiftUI

struct PXNetworkSettingsView: View {
    @ObservedObject private var settings = PXAppSettings.shared

    var body: some View {
        SettingsGlassPage {
            SettingsGlassSection("请求标识") {
                SettingsTextRow("User-Agent", text: $settings.customUserAgent, prompt: "留空使用默认 PlayerX/1.0")
                SettingsNote("自定义 UA 会用于 Jellyfin / Emby / WebDAV / MacCMS 等外部源请求；部分站点会按 UA 放行。")
            }
            SettingsGlassSection("网络缓冲") {
                SettingsNote("播放缓冲策略由内核管理：Pillarbox 使用系统 HLS 缓冲；Erika 使用 FFmpeg read-ahead。")
            }
        }
        .navigationTitle("网络")
        .pxInlineNavigationTitle()
    }
}
